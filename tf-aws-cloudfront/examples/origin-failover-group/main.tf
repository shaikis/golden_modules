# =============================================================================
# EXAMPLE: Origin Failover Group
#
# CloudFront Origin Group with automatic failover:
#   Primary origin  — S3 bucket in us-east-1 (replicated, active)
#   Failover origin — S3 bucket in us-west-2 (replica, passive)
#
# If the primary returns any of the configured HTTP status codes
# (500, 502, 503, 504) CloudFront automatically retries the request
# against the failover origin — transparent to the end user.
#
# Pattern:
#   - Both buckets are private (no public access)
#   - OAC grants CloudFront read access to each bucket independently
#   - S3 Cross-Region Replication keeps the failover bucket in sync
#   - CloudWatch alarms on 5xx error rate alert on-call before failover
#     becomes load-bearing
# =============================================================================

provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "failover"
  region = "us-west-2"
}

# CloudFront + Lambda@Edge must be deployed via us-east-1 provider
provider "aws" {
  region = "us-east-1"
}

# ── Primary S3 bucket (us-east-1) ────────────────────────────────────────────
resource "aws_s3_bucket" "primary" {
  provider      = aws.primary
  bucket        = "${var.name}-primary-${var.environment}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider                = aws.primary
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}

# ── Failover S3 bucket (us-west-2) ───────────────────────────────────────────
resource "aws_s3_bucket" "failover" {
  provider      = aws.failover
  bucket        = "${var.name}-failover-${var.environment}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "failover" {
  provider                = aws.failover
  bucket                  = aws_s3_bucket.failover.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "failover" {
  provider = aws.failover
  bucket   = aws_s3_bucket.failover.id
  versioning_configuration { status = "Enabled" }
}

# ── S3 Cross-Region Replication (primary → failover) ─────────────────────────
data "aws_iam_policy_document" "replication_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["s3.amazonaws.com"] }
  }
}

resource "aws_iam_role" "replication" {
  name               = "${var.name}-s3-replication-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

resource "aws_iam_role_policy" "replication" {
  name = "${var.name}-replication-policy"
  role = aws_iam_role.replication.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = "${aws_s3_bucket.failover.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "primary_to_failover" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  role     = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.failover.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [aws_s3_bucket_versioning.primary, aws_s3_bucket_versioning.failover]
}

# ── CloudFront (must use global provider, resources live in us-east-1) ────────
module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-failover"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  aliases             = var.domain_names
  default_root_object = "index.html"
  comment             = "${var.name} — origin failover group demo"

  viewer_certificate = length(var.domain_names) > 0 ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  } : { cloudfront_default_certificate = true }

  price_class     = var.price_class
  http_version    = "http2and3"
  is_ipv6_enabled = true

  # ── OAC for both origins ──────────────────────────────────────────────────
  origin_access_controls = {
    primary-oac = {
      description                       = "OAC for ${var.name} primary (us-east-1) bucket"
      origin_access_control_origin_type = "s3"
      signing_behavior                  = "always"
      signing_protocol                  = "sigv4"
    }
    failover-oac = {
      description                       = "OAC for ${var.name} failover (us-west-2) bucket"
      origin_access_control_origin_type = "s3"
      signing_behavior                  = "always"
      signing_protocol                  = "sigv4"
    }
  }

  origins = [
    {
      origin_id   = "primary-s3"
      domain_name = aws_s3_bucket.primary.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_control_id = module.cloudfront.origin_access_control_ids["primary-oac"]
      }
    },
    {
      origin_id   = "failover-s3"
      domain_name = aws_s3_bucket.failover.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_control_id = module.cloudfront.origin_access_control_ids["failover-oac"]
      }
    },
  ]

  # ── Origin Group: CloudFront tries primary first; on 5xx falls back to failover
  origin_groups = [{
    origin_group_id = "primary-with-failover"
    failover_criteria_status_codes = [500, 502, 503, 504]
    members = [
      { origin_id = "primary-s3" },
      { origin_id = "failover-s3" },
    ]
  }]

  # Point the cache behaviors at the origin GROUP (not a single origin)
  default_cache_behavior = {
    target_origin_id       = "primary-with-failover"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  ordered_cache_behaviors = [
    # Immutable assets — never need failover retry after 1-year cache
    {
      path_pattern           = "/assets/*"
      target_origin_id       = "primary-with-failover"
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

  # 403 from private S3 → remap as 404 (avoids leaking existence of objects)
  custom_error_responses = [
    { error_code = 403, response_code = 404, response_page_path = "/404.html", error_caching_min_ttl = 10 },
    { error_code = 404, response_code = 404, response_page_path = "/404.html", error_caching_min_ttl = 10 },
  ]

  logging_config = var.log_bucket != null ? {
    bucket          = var.log_bucket
    prefix          = "${var.name}/cloudfront/"
    include_cookies = false
  } : null
}

# ── S3 bucket policies — allow CloudFront OAC on both origins ────────────────
resource "aws_s3_bucket_policy" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.primary.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = module.cloudfront.distribution_arn }
      }
    }]
  })
}

resource "aws_s3_bucket_policy" "failover" {
  provider = aws.failover
  bucket   = aws_s3_bucket.failover.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.failover.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = module.cloudfront.distribution_arn }
      }
    }]
  })
}

# ── CloudWatch alarm — alert when primary bucket starts failing ───────────────
resource "aws_cloudwatch_metric_alarm" "origin_error_rate" {
  alarm_name          = "${var.name}-cloudfront-5xx-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1   # > 1 % triggers the alarm
  alarm_description   = "CloudFront 5xx error rate exceeds 1% — failover origin may be serving traffic"

  metric_query {
    id          = "error_rate"
    expression  = "100 * errors / requests"
    label       = "5xx Error Rate (%)"
    return_data = true
  }
  metric_query {
    id = "errors"
    metric {
      metric_name = "5xxErrorRate"
      namespace   = "AWS/CloudFront"
      period      = 60
      stat        = "Sum"
      dimensions  = { DistributionId = module.cloudfront.distribution_id }
    }
  }
  metric_query {
    id = "requests"
    metric {
      metric_name = "Requests"
      namespace   = "AWS/CloudFront"
      period      = 60
      stat        = "Sum"
      dimensions  = { DistributionId = module.cloudfront.distribution_id }
    }
  }

  alarm_actions = var.alarm_sns_arn != null ? [var.alarm_sns_arn] : []
  ok_actions    = var.alarm_sns_arn != null ? [var.alarm_sns_arn] : []
  treat_missing_data = "notBreaching"
}

output "cloudfront_domain"    { value = module.cloudfront.distribution_domain_name }
output "cloudfront_id"        { value = module.cloudfront.distribution_id }
output "primary_bucket"       { value = aws_s3_bucket.primary.bucket }
output "failover_bucket"      { value = aws_s3_bucket.failover.bucket }
output "site_url" {
  value = length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${module.cloudfront.distribution_domain_name}"
}
