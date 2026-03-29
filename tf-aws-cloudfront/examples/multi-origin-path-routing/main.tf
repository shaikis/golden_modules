# =============================================================================
# EXAMPLE: Multi-Origin Path Routing
#
# One CloudFront distribution with three distinct origins:
#   - S3 (OAC) for static web assets (default: /*)
#   - ALB for the application API (/api/*)
#   - Separate private S3 bucket for user-uploaded media (/media/*, /uploads/*)
#
# This avoids having to run separate distributions and lets you use a single
# domain for the whole product.
# =============================================================================

provider "aws" { region = "us-east-1" }

# ── Static-assets S3 bucket (private) ────────────────────────────────────────
resource "aws_s3_bucket" "static" {
  bucket        = "${var.name}-static-${var.environment}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Media / uploads S3 bucket (private) ──────────────────────────────────────
resource "aws_s3_bucket" "media" {
  bucket        = "${var.name}-media-${var.environment}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── CloudFront ────────────────────────────────────────────────────────────────
module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-multi"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  aliases             = var.domain_names
  default_root_object = "index.html"
  comment             = "${var.name} — multi-origin path routing"

  viewer_certificate = length(var.domain_names) > 0 ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  } : { cloudfront_default_certificate = true }

  price_class     = var.price_class
  http_version    = "http2and3"
  is_ipv6_enabled = true
  web_acl_id      = var.waf_web_acl_arn

  # ── OAC for each private S3 origin ─────────────────────────────────────────
  origin_access_controls = {
    static-oac = {
      description                       = "OAC for ${var.name} static assets"
      origin_access_control_origin_type = "s3"
      signing_behavior                  = "always"
      signing_protocol                  = "sigv4"
    }
    media-oac = {
      description                       = "OAC for ${var.name} media uploads"
      origin_access_control_origin_type = "s3"
      signing_behavior                  = "always"
      signing_protocol                  = "sigv4"
    }
  }

  origins = [
    # Origin 1: static web assets (S3 + OAC)
    {
      origin_id   = "static-s3"
      domain_name = aws_s3_bucket.static.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_control_id = module.cloudfront.origin_access_control_ids["static-oac"]
      }
    },
    # Origin 2: ALB — application API
    {
      origin_id   = "api-alb"
      domain_name = var.alb_dns_name
      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 60
        origin_read_timeout      = 60
      }
      # Prevent direct ALB access by requiring this secret header
      custom_headers = [
        { name = "X-CloudFront-Secret", value = var.cloudfront_secret_header_value }
      ]
      # Origin Shield reduces ALB load from multiple CF PoPs
      origin_shield = {
        enabled              = true
        origin_shield_region = "us-east-1"
      }
    },
    # Origin 3: media / user-uploaded content (separate S3 + OAC)
    {
      origin_id   = "media-s3"
      domain_name = aws_s3_bucket.media.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_control_id = module.cloudfront.origin_access_control_ids["media-oac"]
      }
    },
  ]

  # ── Default: static assets from S3 ─────────────────────────────────────────
  default_cache_behavior = {
    target_origin_id       = "static-s3"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    # CachingOptimized
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    min_ttl                    = 0
    default_ttl                = 86400
    max_ttl                    = 31536000
  }

  ordered_cache_behaviors = [
    # /api/* — dynamic; forward everything to ALB, never cache
    {
      path_pattern           = "/api/*"
      target_origin_id       = "api-alb"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      # CachingDisabled
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      # AllViewer — forward all headers + cookies to the ALB
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
      response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
      min_ttl                  = 0
      default_ttl              = 0
      max_ttl                  = 0
    },
    # /media/* — user-uploaded content from the media bucket; moderate caching
    {
      path_pattern           = "/media/*"
      target_origin_id       = "media-s3"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 3600     # 1 hour — content can change
      max_ttl                = 86400    # 1 day max
    },
    # /uploads/* — same media bucket, same moderate policy
    {
      path_pattern           = "/uploads/*"
      target_origin_id       = "media-s3"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
    },
    # /assets/* — content-hashed filenames; cache for 1 year
    {
      path_pattern           = "/assets/*"
      target_origin_id       = "static-s3"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 31536000
      default_ttl            = 31536000
      max_ttl                = 31536000
    },
  ]

  # S3 private bucket returns 403 for missing objects — remap to 404
  custom_error_responses = [
    { error_code = 403, response_code = 404, response_page_path = "/404.html", error_caching_min_ttl = 30 },
    { error_code = 404, response_code = 404, response_page_path = "/404.html", error_caching_min_ttl = 30 },
    { error_code = 502, error_caching_min_ttl = 0 },
    { error_code = 503, error_caching_min_ttl = 0 },
    { error_code = 504, error_caching_min_ttl = 0 },
  ]

  logging_config = var.log_bucket != null ? {
    bucket          = var.log_bucket
    prefix          = "${var.name}/cloudfront/"
    include_cookies = false
  } : null
}

# ── S3 bucket policies — grant CloudFront OAC read access ────────────────────
resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.static.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = module.cloudfront.distribution_arn }
      }
    }]
  })
}

resource "aws_s3_bucket_policy" "media" {
  bucket = aws_s3_bucket.media.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.media.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = module.cloudfront.distribution_arn }
      }
    }]
  })
}

output "cloudfront_domain"  { value = module.cloudfront.distribution_domain_name }
output "cloudfront_id"      { value = module.cloudfront.distribution_id }
output "static_bucket"      { value = aws_s3_bucket.static.bucket }
output "media_bucket"       { value = aws_s3_bucket.media.bucket }
output "site_url" {
  value = length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${module.cloudfront.distribution_domain_name}"
}
