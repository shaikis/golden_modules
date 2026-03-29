# ===========================================================================
# NAMING & TAGGING
# ===========================================================================
variable "name" {
  description = "WebACL name."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = ""
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ===========================================================================
# SCOPE
# ===========================================================================
variable "scope" {
  description = <<-EOT
    WAF scope:
      CLOUDFRONT - Attach to CloudFront distributions (resources must be in us-east-1)
      REGIONAL   - Attach to ALB, API GW, AppSync, Cognito, App Runner (same region as resources)
  EOT
  type    = string
  default = "REGIONAL"
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "description" {
  description = "Human-readable description of the WebACL."
  type        = string
  default     = ""
}

# ===========================================================================
# DEFAULT ACTION
# ===========================================================================
variable "default_action" {
  description = "Default action for requests not matching any rule. allow | block"
  type        = string
  default     = "allow"
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be allow or block."
  }
}

# ===========================================================================
# TOKEN DOMAINS (challenge/CAPTCHA)
# ===========================================================================
variable "token_domains" {
  description = "List of domains for WAF token management (shared challenge/CAPTCHA tokens across subdomains)."
  type        = list(string)
  default     = []
}

# ===========================================================================
# MANAGED RULE GROUPS
# ===========================================================================
variable "managed_rule_groups" {
  description = <<-EOT
    List of AWS or marketplace managed rule group configurations.

    Common AWS managed rule groups:
      AWSManagedRulesCommonRuleSet          - OWASP Top 10 core rule set
      AWSManagedRulesAdminProtectionRuleSet - Block access to admin panels
      AWSManagedRulesKnownBadInputsRuleSet  - Known attack patterns
      AWSManagedRulesSQLiRuleSet            - SQL injection protection
      AWSManagedRulesLinuxRuleSet           - Linux OS-specific attacks
      AWSManagedRulesUnixRuleSet            - UNIX OS-specific attacks
      AWSManagedRulesWindowsRuleSet         - Windows OS-specific attacks
      AWSManagedRulesPHPRuleSet             - PHP-specific attacks
      AWSManagedRulesWordPressRuleSet       - WordPress-specific attacks
      AWSManagedRulesAmazonIpReputationList - AWS IP reputation list (bots, malware)
      AWSManagedRulesAnonymousIpList        - VPNs, Tor, proxies, hosting providers
      AWSManagedRulesBotControlRuleSet      - Automated bot management
      AWSManagedRulesATPRuleSet             - Account takeover prevention

    Fields:
      name              - Rule group name
      vendor_name       - AWS (for AWS managed) or marketplace vendor
      version           - Optional version override (null = latest)
      priority          - Rule evaluation priority (lower = first)
      override_action   - none | count (count = observe-only mode for testing)
      cloudwatch_metrics_enabled - Emit CloudWatch metrics for this rule group
      sampled_requests_enabled   - Sample requests for debugging
      excluded_rules    - List of individual rule names to disable within the group
      rule_action_overrides - Override action for specific rules within the group:
        name   - Rule name within the group
        action - allow | block | count | captcha | challenge
  EOT
  type = list(object({
    name                       = string
    vendor_name                = optional(string, "AWS")
    version                    = optional(string, null)
    priority                   = number
    override_action            = optional(string, "none")
    cloudwatch_metrics_enabled = optional(bool, true)
    sampled_requests_enabled   = optional(bool, true)
    excluded_rules             = optional(list(string), [])
    rule_action_overrides = optional(list(object({
      name   = string
      action = string # allow | block | count | captcha | challenge
    })), [])
  }))
  default = []
}

# ===========================================================================
# IP SETS
# ===========================================================================
variable "ip_sets" {
  description = <<-EOT
    Map of IP sets to create. Use these in ip_set_rules.
    Key = logical name:
      name               - IP set name
      description        - Description
      ip_address_version - IPV4 | IPV6
      addresses          - List of CIDR ranges
  EOT
  type = map(object({
    name               = optional(string, null)
    description        = optional(string, "")
    ip_address_version = optional(string, "IPV4")
    addresses          = list(string)
  }))
  default = {}
}

# ===========================================================================
# REGEX PATTERN SETS
# ===========================================================================
variable "regex_pattern_sets" {
  description = <<-EOT
    Map of regex pattern sets. Use these in custom_rules.
    Key = logical name:
      name        - Pattern set name
      description - Description
      patterns    - List of regex patterns (POSIX extended)
  EOT
  type = map(object({
    name        = optional(string, null)
    description = optional(string, "")
    patterns    = list(string)
  }))
  default = {}
}

# ===========================================================================
# RATE-BASED RULES
# ===========================================================================
variable "rate_based_rules" {
  description = <<-EOT
    Rate-based rules to throttle excessive requests.

      name               - Rule name
      priority           - Evaluation priority
      action             - block | count | captcha | challenge
      limit              - Request threshold per 5-minute window (100-2,000,000,000)
      aggregate_key_type - IP | FORWARDED_IP | CONSTANT | CUSTOM_KEYS
      forwarded_ip_config - Required when aggregate_key_type = FORWARDED_IP:
        header_name        - Header containing client IP (e.g. X-Forwarded-For)
        fallback_behavior  - MATCH | NO_MATCH
      scope_down_statement - Optional narrowing filter (same structure as custom rule statements)
      cloudwatch_metrics_enabled - Emit CloudWatch metrics
      sampled_requests_enabled   - Sample blocked requests
  EOT
  type = list(object({
    name               = string
    priority           = number
    action             = optional(string, "block")
    limit              = optional(number, 2000)
    aggregate_key_type = optional(string, "IP")
    cloudwatch_metrics_enabled = optional(bool, true)
    sampled_requests_enabled   = optional(bool, true)

    forwarded_ip_config = optional(object({
      header_name       = string
      fallback_behavior = optional(string, "MATCH")
    }), null)
  }))
  default = []
}

# ===========================================================================
# IP SET RULES (allow-list or block-list)
# ===========================================================================
variable "ip_set_rules" {
  description = <<-EOT
    Rules that match against IP sets (allow known-good CIDRs, block known-bad CIDRs).

      name        - Rule name
      priority    - Evaluation priority
      action      - allow | block | count | captcha | challenge
      ip_set_key  - Key from var.ip_sets to match against
      ip_set_arn  - Alternative: reference an existing IP set ARN directly
      negated     - Negate the match (true = match everything NOT in the IP set)
      forwarded_ip_config - Use X-Forwarded-For instead of source IP:
        header_name       - Header name
        fallback_behavior - MATCH | NO_MATCH
      cloudwatch_metrics_enabled - Emit CloudWatch metrics
      sampled_requests_enabled   - Sample matched requests
  EOT
  type = list(object({
    name       = string
    priority   = number
    action     = string
    ip_set_key = optional(string, null)
    ip_set_arn = optional(string, null)
    negated    = optional(bool, false)
    cloudwatch_metrics_enabled = optional(bool, true)
    sampled_requests_enabled   = optional(bool, true)

    forwarded_ip_config = optional(object({
      header_name       = string
      fallback_behavior = optional(string, "MATCH")
    }), null)
  }))
  default = []
}

# ===========================================================================
# GEO MATCH RULES
# ===========================================================================
variable "geo_match_rules" {
  description = <<-EOT
    Rules that allow or block traffic based on geographic origin.

      name               - Rule name
      priority           - Evaluation priority
      action             - allow | block | count | captcha | challenge
      country_codes      - List of ISO 3166-1-alpha-2 codes (e.g. ["RU", "CN", "KP"])
      negated            - Negate (true = allow only these countries, block everything else)
      forwarded_ip_config - Use X-Forwarded-For header for geolocation
  EOT
  type = list(object({
    name          = string
    priority      = number
    action        = string
    country_codes = list(string)
    negated       = optional(bool, false)
    cloudwatch_metrics_enabled = optional(bool, true)
    sampled_requests_enabled   = optional(bool, true)

    forwarded_ip_config = optional(object({
      header_name       = string
      fallback_behavior = optional(string, "MATCH")
    }), null)
  }))
  default = []
}

# ===========================================================================
# CUSTOM RULES (byte match, string match, size constraint, sqli, xss)
# ===========================================================================
variable "custom_rules" {
  description = <<-EOT
    Fully custom WAF rules. Each rule supports a single top-level statement
    (use AND/OR/NOT via nested_statement for complex logic).

      name     - Rule name
      priority - Evaluation priority
      action   - allow | block | count | captcha | challenge

    Statement types (choose one per rule):
      byte_match_statement:
        search_string         - String to search for
        field_to_match_type   - ALL_QUERY_ARGS | BODY | HEADER | METHOD | QUERY_STRING | SINGLE_HEADER | URI_PATH
        header_name           - Required when field_to_match_type = SINGLE_HEADER
        positional_constraint - EXACTLY | STARTS_WITH | ENDS_WITH | CONTAINS | CONTAINS_WORD
        text_transformations  - List of: NONE | COMPRESS_WHITE_SPACE | HTML_ENTITY_DECODE | LOWERCASE | CMD_LINE | URL_DECODE | BASE64_DECODE | HEX_DECODE | MD5 | REPLACE_COMMENTS | ESCAPE_SEQ_DECODE | SQL_HEX_DECODE | CSS_DECODE | JS_DECODE | NORMALIZE_PATH | NORMALIZE_PATH_WIN | REMOVE_NULLS | REPLACE_NULLS | BASE64_DECODE_EXT | URL_DECODE_UNI | UTF8_TO_UNICODE
      sqli_match_statement: (SQL injection detection)
        field_to_match_type / text_transformations (same as byte_match)
      xss_match_statement: (Cross-site scripting detection)
        field_to_match_type / text_transformations (same as byte_match)
      size_constraint_statement:
        field_to_match_type
        comparison_operator   - EQ | NE | LE | LT | GE | GT
        size                  - Size in bytes
        text_transformations
      regex_pattern_set_statement:
        regex_pattern_set_key - Key from var.regex_pattern_sets
        field_to_match_type
        text_transformations
  EOT
  type = list(object({
    name     = string
    priority = number
    action   = string
    cloudwatch_metrics_enabled = optional(bool, true)
    sampled_requests_enabled   = optional(bool, true)

    byte_match_statement = optional(object({
      search_string         = string
      field_to_match_type   = string
      header_name           = optional(string, null)
      positional_constraint = optional(string, "CONTAINS")
      text_transformations  = optional(list(string), ["NONE"])
    }), null)

    sqli_match_statement = optional(object({
      field_to_match_type  = string
      header_name          = optional(string, null)
      text_transformations = optional(list(string), ["URL_DECODE", "HTML_ENTITY_DECODE"])
    }), null)

    xss_match_statement = optional(object({
      field_to_match_type  = string
      header_name          = optional(string, null)
      text_transformations = optional(list(string), ["URL_DECODE", "HTML_ENTITY_DECODE"])
    }), null)

    size_constraint_statement = optional(object({
      field_to_match_type  = string
      header_name          = optional(string, null)
      comparison_operator  = string
      size                 = number
      text_transformations = optional(list(string), ["NONE"])
    }), null)

    regex_pattern_set_statement = optional(object({
      regex_pattern_set_key = string
      field_to_match_type   = string
      header_name           = optional(string, null)
      text_transformations  = optional(list(string), ["NONE"])
    }), null)
  }))
  default = []
}

# ===========================================================================
# LOGGING
# ===========================================================================
variable "logging_config" {
  description = <<-EOT
    WAF logging configuration. Logs full request details for blocked and allowed requests.

      log_destination_arns - List of destination ARNs (S3 bucket ARN, Kinesis Firehose ARN, or CloudWatch Log Group ARN)
                             Prefix: S3 = "aws-waf-logs-*", Firehose = "aws-waf-logs-*", CWL = any
      redacted_fields      - List of request fields to redact from logs (SINGLE_HEADER | METHOD | QUERY_STRING | URI_PATH | BODY)
      filter_conditions    - Sampling filters to reduce log volume:
        behavior           - KEEP | DROP
        requirement        - MEETS_ALL | MEETS_ANY
        conditions         - list of { action_condition: ALLOW|BLOCK|COUNT|CAPTCHA|CHALLENGE|EXCLUDED_AS_COUNT }
  EOT
  type = object({
    log_destination_arns = list(string)
    redacted_fields = optional(list(object({
      type        = string
      header_name = optional(string, null)
    })), [])
    filter_conditions = optional(list(object({
      behavior    = string
      requirement = string
      conditions = list(object({
        action_condition = string
      }))
    })), [])
  })
  default = null
}

# ===========================================================================
# RESOURCE ASSOCIATIONS
# ===========================================================================
variable "resource_arns" {
  description = "List of resource ARNs to associate this WebACL with (ALB, API GW stage, AppSync, Cognito, App Runner). Not used for CLOUDFRONT scope."
  type        = list(string)
  default     = []
}

# ===========================================================================
# CLOUDWATCH METRICS (WebACL level)
# ===========================================================================
variable "cloudwatch_metrics_enabled" {
  description = "Enable CloudWatch metrics for the WebACL."
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Enable request sampling for the WebACL."
  type        = bool
  default     = true
}

variable "metric_name" {
  description = "CloudWatch metric name for the WebACL. Defaults to the WebACL name."
  type        = string
  default     = null
}
