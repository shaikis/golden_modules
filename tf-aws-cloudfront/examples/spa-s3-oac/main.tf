# =============================================================================
# EXAMPLE: SPA (React / Angular / Vue) — Private S3 + OAC
#
# Modern single-page app pattern:
#   - S3 bucket is fully PRIVATE (no public access)
#   - Origin Access Control (OAC) grants CloudFront exclusive S3 access
#   - All routes (/*) return index.html so the client-side router handles them
#   - Custom domain with ACM certificate
#   - Cache-busted assets (/assets/*) cached aggressively (1 year)
#   - index.html and /api/* NEVER cached
# =============================================================================

provider "aws" { region = "us-east-1" }

# Private S3 bucket — no public access
resource "aws_s3_bucket" "spa" {
  bucket        = "${var.name}-spa-${var.environment}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "spa" {
  bucket                  = aws_s3_bucket.spa.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "spa" {
  bucket = aws_s3_bucket.spa.id
  versioning_configuration { status = "Enabled" }
}

module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-spa"
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  aliases             = var.domain_names
  default_root_object = "index.html"

  viewer_certificate = length(var.domain_names) > 0 ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  } : { cloudfront_default_certificate = true }

  # ── OAC — CloudFront gets exclusive private S3 access ────────────────────
  origin_access_controls = {
    spa-oac = {
      description                       = "OAC for ${var.name} SPA bucket"
      origin_access_control_origin_type = "s3"
      signing_behavior                  = "always"
      signing_protocol                  = "sigv4"
    }
  }

  origins = [{
    origin_id   = "spa-s3"
    domain_name = aws_s3_bucket.spa.bucket_regional_domain_name
    s3_origin_config = {
      origin_access_control_id = module.cloudfront.origin_access_control_ids["spa-oac"]
    }
  }]

  # ── Default: serve index.html for all routes (SPA client-side routing) ───
  default_cache_behavior = {
    target_origin_id       = "spa-s3"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    # CachingOptimized
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # SecurityHeadersPolicy — HSTS, X-Frame-Options, etc.
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    min_ttl     = 0
    default_ttl = 86400    # 1 day
    max_ttl     = 31536000 # 1 year
  }

  ordered_cache_behaviors = [
    # /assets/* — content-hashed filenames, cache for 1 year
    {
      path_pattern           = "/assets/*"
      target_origin_id       = "spa-s3"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 31536000
      default_ttl            = 31536000
      max_ttl                = 31536000
    },
    # /static/* — same as assets (webpack/vite chunk filenames are hashed)
    {
      path_pattern           = "/static/*"
      target_origin_id       = "spa-s3"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 31536000
      default_ttl            = 31536000
      max_ttl                = 31536000
    },
    # index.html — never cache (new deployments take effect immediately)
    {
      path_pattern           = "/index.html"
      target_origin_id       = "spa-s3"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    },
  ]

  # SPA routing: 403/404 from S3 → serve index.html with 200
  # (S3 returns 403 for missing files when bucket is private)
  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
    { error_code = 404, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
  ]

  price_class     = var.price_class
  http_version    = "http2and3"
  is_ipv6_enabled = true
}

# Grant CloudFront OAC permission to read the S3 bucket
resource "aws_s3_bucket_policy" "spa" {
  bucket = aws_s3_bucket.spa.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.spa.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = module.cloudfront.distribution_arn
        }
      }
    }]
  })
}

output "cloudfront_domain"    { value = module.cloudfront.distribution_domain_name }
output "cloudfront_id"        { value = module.cloudfront.distribution_id }
output "s3_bucket_name"       { value = aws_s3_bucket.spa.bucket }
output "oac_id"               { value = module.cloudfront.origin_access_control_ids["spa-oac"] }
output "spa_url" {
  value = length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${module.cloudfront.distribution_domain_name}"
}
