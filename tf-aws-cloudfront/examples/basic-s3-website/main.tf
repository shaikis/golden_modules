# =============================================================================
# EXAMPLE: Basic — S3 Static Website
#
# Simplest possible CloudFront usage.
# Serves a public S3 static website with HTTPS and global edge caching.
# Use this as your starting point.
# =============================================================================

provider "aws" { region = "us-east-1" }

# Public S3 bucket for static website
resource "aws_s3_bucket" "website" {
  bucket = "${var.name}-website-${var.environment}"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document { suffix = "index.html" }
  error_document { key    = "error.html" }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.website]
}

module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-website"
  environment = var.environment

  origins = [{
    origin_id   = "s3-website"
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    custom_origin_config = {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"   # S3 website endpoint is HTTP only
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }]

  default_cache_behavior = {
    target_origin_id       = "s3-website"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    # CachingOptimized managed policy
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Use CloudFront default *.cloudfront.net certificate (no custom domain needed)
  viewer_certificate = { cloudfront_default_certificate = true }
}

output "website_url" { value = "https://${module.cloudfront.distribution_domain_name}" }
