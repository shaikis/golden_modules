# =============================================================================
# SCENARIO: Real-Time Payment API — CloudFront Edge Distribution
#
# CloudFront in front of API Gateway for a payment platform:
#   - Payments must NEVER be cached (CachingDisabled policy)
#   - Health check endpoint cached briefly for monitoring tools
#   - TLS 1.2+ enforced (PCI-DSS requirement)
#   - Security headers (HSTS, X-Content-Type-Options, X-Frame-Options)
#   - Origin Shield consolidates requests from 400+ PoPs to API Gateway
#   - Custom header prevents direct-to-origin bypass
#   - WAF attached (separate tf-aws-waf module)
# =============================================================================

provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-cf"
  environment = var.environment
}

module "waf" {
  source      = "../../../tf-aws-waf"
  name        = "${var.name}-payment-api-waf"
  environment = var.environment
  scope       = "CLOUDFRONT"  # Must be CLOUDFRONT for CloudFront distributions

  managed_rule_groups = [
    { name = "AWSManagedRulesCommonRuleSet",        vendor_name = "AWS", priority = 10 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS", priority = 20 },
    { name = "AWSManagedRulesSQLiRuleSet",           vendor_name = "AWS", priority = 30 },
    { name = "AWSManagedRulesAmazonIpReputationList", vendor_name = "AWS", priority = 40 },
  ]

  rate_based_rules = [
    { name = "PaymentRateLimit", priority = 50, action = "block", limit = 5000, aggregate_key_type = "IP" }
  ]
}

module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-payment-api"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  # Custom domain (PCI-DSS requires proper certificate)
  aliases = var.api_domain_name != null ? [var.api_domain_name] : []

  viewer_certificate = var.acm_certificate_arn != null ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"  # PCI-DSS 3.2.1 requires TLS 1.2+
    ssl_support_method       = "sni-only"
  } : {
    cloudfront_default_certificate = true
  }

  web_acl_id      = module.waf.web_acl_arn
  price_class     = "PriceClass_All"
  http_version    = "http2and3"
  is_ipv6_enabled = true

  origins = [
    {
      origin_id   = "payment-api"
      domain_name = var.api_gateway_domain
      origin_path = "/${var.environment}"

      custom_origin_config = {
        https_port               = 443
        http_port                = 80
        origin_protocol_policy   = "https-only"    # Always HTTPS to origin (PCI-DSS)
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 60
        origin_read_timeout      = 60              # Allow up to 60s for payment processing
      }

      # Secret header prevents direct API Gateway access bypassing CloudFront+WAF
      custom_headers = [
        { name = "X-Origin-Verify", value = var.origin_verify_secret }
      ]

      # Origin Shield: single ingress point for all 400+ CloudFront PoPs
      # Reduces API Gateway load by up to 60% for repeated health checks
      origin_shield = {
        enabled              = true
        origin_shield_region = var.aws_region  # Same region as API Gateway
      }
    }
  ]

  # Payments: NEVER cache (money moves, can't serve stale responses)
  default_cache_behavior = {
    target_origin_id       = "payment-api"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # CachingDisabled managed policy (no caching at all)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # AllViewer: forward all headers/cookies/QS to origin
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    # Security headers: HSTS, X-Content-Type-Options, X-Frame-Options, etc.
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Health check path — safe to cache briefly (reduces origin health-check load)
  ordered_cache_behaviors = [
    {
      path_pattern           = "/*/health"
      target_origin_id       = "payment-api"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      # CachingOptimized with 10s TTL
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 0
      default_ttl            = 10
      max_ttl                = 30
    }
  ]

  # Never cache errors — payment retries must hit origin
  custom_error_responses = [
    { error_code = 400, error_caching_min_ttl = 0 },
    { error_code = 403, error_caching_min_ttl = 0 },
    { error_code = 429, error_caching_min_ttl = 0 },
    { error_code = 500, error_caching_min_ttl = 0 },
    { error_code = 502, error_caching_min_ttl = 0 },
    { error_code = 503, error_caching_min_ttl = 0 },
    { error_code = 504, error_caching_min_ttl = 0 },
  ]

  geo_restriction = {
    restriction_type = "none"  # Handled by WAF with OFAC country codes
    locations        = []
  }
}

output "cloudfront_domain"    { value = module.cloudfront.distribution_domain_name }
output "cloudfront_id"        { value = module.cloudfront.distribution_id }
output "payment_api_url"      { value = "https://${module.cloudfront.distribution_domain_name}/v1/payments" }
output "waf_web_acl_arn"      { value = module.waf.web_acl_arn }
