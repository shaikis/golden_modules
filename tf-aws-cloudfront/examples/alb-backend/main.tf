# =============================================================================
# EXAMPLE: ALB Backend (ECS / EKS / EC2 Application)
#
# CloudFront in front of an internal ALB running a containerised application.
# Pattern:
#   - ALB is internet-facing but protected by a secret header check
#     (ALB listener rule only accepts requests with X-CloudFront-Secret)
#   - CloudFront adds the secret header on every forward request
#   - WAF attached to CloudFront for OWASP + rate limiting
#   - Dynamic API responses: never cached
#   - Static assets served from the same ALB origin, cached at edge
#   - Custom domain with ACM certificate
# =============================================================================

provider "aws" { region = var.aws_region }

module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-app"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  aliases = var.domain_names
  comment = "${var.name} application — ALB backend"

  viewer_certificate = length(var.domain_names) > 0 ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  } : { cloudfront_default_certificate = true }

  web_acl_id      = var.waf_web_acl_arn
  price_class     = "PriceClass_100"  # US + Europe only (cost-optimised)
  http_version    = "http2and3"
  is_ipv6_enabled = true

  origins = [{
    origin_id   = "alb-backend"
    domain_name = var.alb_dns_name

    custom_origin_config = {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }

    # Secret header — ALB listener rule rejects requests missing this header
    # Prevents attackers from bypassing CloudFront and hitting ALB directly
    custom_headers = [
      { name = "X-CloudFront-Secret", value = var.cloudfront_secret_header_value }
    ]

    # Origin Shield — consolidates CloudFront PoP requests to reduce ALB hits
    origin_shield = {
      enabled              = true
      origin_shield_region = var.aws_region
    }
  }]

  # ── Default: API / dynamic content — NEVER cache ─────────────────────────
  default_cache_behavior = {
    target_origin_id       = "alb-backend"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # CachingDisabled — no caching for dynamic responses
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # AllViewer — forward all headers/cookies to ALB (session cookies etc.)
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
    # Security headers policy
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  ordered_cache_behaviors = [
    # /static/* — hashed filenames, cache aggressively at edge
    {
      path_pattern           = "/static/*"
      target_origin_id       = "alb-backend"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      # CachingOptimized
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
    },
    # /media/* — user-uploaded content, moderate caching
    {
      path_pattern           = "/media/*"
      target_origin_id       = "alb-backend"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 3600     # 1 hour
      max_ttl                = 86400    # 1 day
    },
    # /health — brief cache so monitors don't all hit ALB
    {
      path_pattern           = "/health"
      target_origin_id       = "alb-backend"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = false
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 10
      max_ttl                = 30
    },
  ]

  custom_error_responses = [
    { error_code = 502, error_caching_min_ttl = 0 },
    { error_code = 503, error_caching_min_ttl = 0 },
    { error_code = 504, error_caching_min_ttl = 0 },
  ]

  geo_restriction = var.allowed_countries != null ? {
    restriction_type = "whitelist"
    locations        = var.allowed_countries
  } : {
    restriction_type = "none"
    locations        = []
  }

  logging_config = var.log_bucket != null ? {
    bucket          = var.log_bucket
    prefix          = "${var.name}/cloudfront/"
    include_cookies = false
  } : null
}

output "cloudfront_domain"    { value = module.cloudfront.distribution_domain_name }
output "cloudfront_id"        { value = module.cloudfront.distribution_id }
output "app_url" {
  value = length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${module.cloudfront.distribution_domain_name}"
}
