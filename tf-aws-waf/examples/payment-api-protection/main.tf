# =============================================================================
# SCENARIO: Payment API WAF — Complete Protection Stack
#
# A fintech company's real-time payment API needs:
#   - OWASP Top 10 protection (SQL injection, XSS, bad inputs)
#   - Bot and scraper prevention (AWSManagedRulesBotControlRuleSet)
#   - OFAC/sanctions country geo-blocking (KP, IR, SY, CU)
#   - Rate limiting per IP (prevent payment flooding/DoS)
#   - Trusted partner bank CIDR allow-listing (bypass rate limiting)
#   - Block oversized payment request bodies
#   - AWS IP reputation list (block known malicious IPs)
#   - Log ALL blocked requests to S3 (compliance requirement)
#   - CLOUDFRONT scope (attached to CloudFront, must be us-east-1)
# =============================================================================

provider "aws" { region = "us-east-1" }  # CloudFront WAF MUST be us-east-1

module "payment_waf" {
  source      = "../../"
  name        = "payment-api-protection"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  scope          = "CLOUDFRONT"
  default_action = "allow"
  description    = "Full protection stack for real-time payment API"

  # ── AWS Managed Rule Groups (priority 10–60) ─────────────────────────────
  managed_rule_groups = [
    {
      # OWASP Top 10 core rules — SQL injection, XSS, path traversal
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
      priority    = 10
      override_action = "none"
      excluded_rules  = [
        # Payment requests can have large bodies — don't block on body size here
        # We handle this with our own size constraint custom rule
        "SizeRestrictions_BODY",
      ]
    },
    {
      # JNDI/Log4Shell, Spring4Shell, OGNL injection, Shellshock
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
      priority    = 20
      override_action = "none"
    },
    {
      # SQL injection — deep inspection of body and query strings
      name        = "AWSManagedRulesSQLiRuleSet"
      vendor_name = "AWS"
      priority    = 30
      override_action = "none"
    },
    {
      # AWS-curated list of IPs associated with botnets, malware, TOR exit nodes
      name        = "AWSManagedRulesAmazonIpReputationList"
      vendor_name = "AWS"
      priority    = 40
      override_action = "none"
    },
    {
      # Hosting providers, VPNs, proxies — use COUNT mode (not all VPNs are bad)
      # Payment teams can escalate to "none" (block) after reviewing logs
      name        = "AWSManagedRulesAnonymousIpList"
      vendor_name = "AWS"
      priority    = 50
      override_action = "count"   # Observe mode — switch to "none" to block
      excluded_rules  = []
    },
    {
      # Bot Control — detect and manage automated traffic
      # Using COUNT mode to baseline before blocking (avoid blocking legit partners)
      name        = "AWSManagedRulesBotControlRuleSet"
      vendor_name = "AWS"
      priority    = 60
      override_action = "count"
      rule_action_overrides = [
        # Allow known good bots (Googlebot, etc.) even in bot control mode
        { name = "CategoryVerifiedSearchEngine", action = "allow" },
        { name = "CategoryVerifiedSocialMedia",  action = "allow" },
      ]
    },
  ]

  # ── IP Sets ──────────────────────────────────────────────────────────────
  ip_sets = {
    trusted-partner-banks = {
      description        = "Partner bank CIDR ranges — trusted, bypass rate limiting"
      ip_address_version = "IPV4"
      addresses          = var.trusted_partner_cidrs
    }
    internal-monitoring = {
      description        = "Internal monitoring and health check sources"
      ip_address_version = "IPV4"
      addresses          = var.monitoring_cidrs
    }
  }

  # ── IP Set Rules ─────────────────────────────────────────────────────────
  ip_set_rules = [
    # Allow trusted partner banks BEFORE any rate limiting or geo-blocking
    {
      name       = "AllowTrustedPartnerBanks"
      priority   = 5   # Must be first — allow before geo-block and rate limit
      action     = "allow"
      ip_set_key = "trusted-partner-banks"
    },
    # Allow monitoring tools (health checks, Datadog, PagerDuty probes)
    {
      name       = "AllowInternalMonitoring"
      priority   = 6
      action     = "allow"
      ip_set_key = "internal-monitoring"
    },
  ]

  # ── Geo-Block OFAC Sanctioned Countries ──────────────────────────────────
  geo_match_rules = [
    {
      name          = "BlockOFACSanctionedCountries"
      priority      = 70
      action        = "block"
      country_codes = ["KP", "IR", "SY", "CU", "BY"]  # OFAC + Belarus sanctions
    }
  ]

  # ── Rate-Based Rules ─────────────────────────────────────────────────────
  rate_based_rules = [
    # Primary rate limit per source IP
    {
      name               = "PaymentAPIIPRateLimit"
      priority           = 80
      action             = "block"
      limit              = var.rate_limit_per_5min
      aggregate_key_type = "IP"
    },
    # Secondary: rate limit on X-Forwarded-For (for clients behind proxies)
    {
      name               = "PaymentAPIForwardedIPRateLimit"
      priority           = 81
      action             = "block"
      limit              = var.rate_limit_per_5min
      aggregate_key_type = "FORWARDED_IP"
      forwarded_ip_config = {
        header_name       = "X-Forwarded-For"
        fallback_behavior = "MATCH"
      }
    },
  ]

  # ── Custom Rules ─────────────────────────────────────────────────────────
  custom_rules = [
    # Block oversized request bodies (payment payloads > 100KB are suspicious)
    {
      name     = "BlockOversizedPaymentBodies"
      priority = 90
      action   = "block"
      size_constraint_statement = {
        field_to_match_type = "BODY"
        comparison_operator = "GT"
        size                = 102400  # 100 KB
        text_transformations = ["NONE"]
      }
    },
    # Block SQL injection in URI path (catch path-based SQLi like /v1/payments/1 OR 1=1)
    {
      name     = "BlockSQLiInURI"
      priority = 91
      action   = "block"
      sqli_match_statement = {
        field_to_match_type  = "URI_PATH"
        text_transformations = ["URL_DECODE", "LOWERCASE"]
      }
    },
    # Block XSS in query strings
    {
      name     = "BlockXSSInQueryString"
      priority = 92
      action   = "block"
      xss_match_statement = {
        field_to_match_type  = "QUERY_STRING"
        text_transformations = ["URL_DECODE", "HTML_ENTITY_DECODE"]
      }
    },
  ]

  # ── Logging (compliance — log all blocked requests) ───────────────────────
  logging_config = var.waf_log_bucket_arn != null ? {
    log_destination_arns = [var.waf_log_bucket_arn]
    redacted_fields = [
      # Redact Authorization header (JWT tokens — don't log credentials)
      { type = "SINGLE_HEADER", header_name = "authorization" },
      # Redact x-api-key
      { type = "SINGLE_HEADER", header_name = "x-api-key" },
    ]
    # Log ALL blocked requests, sample everything else (cost control)
    filter_conditions = [
      {
        behavior    = "KEEP"
        requirement = "MEETS_ANY"
        conditions  = [
          { action_condition = "BLOCK" },
          { action_condition = "CAPTCHA" },
          { action_condition = "CHALLENGE" },
        ]
      },
      {
        behavior    = "DROP"
        requirement = "MEETS_ALL"
        conditions  = [
          { action_condition = "ALLOW" }
        ]
      },
    ]
  } : null
}

output "waf_arn"           { value = module.payment_waf.web_acl_arn }
output "waf_id"            { value = module.payment_waf.web_acl_id }
output "waf_capacity"      { value = module.payment_waf.web_acl_capacity }
output "ip_set_arns"       { value = module.payment_waf.ip_set_arns }
