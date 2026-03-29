# ===========================================================================
# NAMING & TAGGING
# ===========================================================================
variable "name" {
  description = "Distribution name used for resource naming and tagging."
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
# DISTRIBUTION CORE
# ===========================================================================
variable "enabled" {
  description = "Whether the CloudFront distribution is enabled to accept end-user requests."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Enable IPv6 for the distribution."
  type        = bool
  default     = true
}

variable "http_version" {
  description = "Maximum HTTP version to support. http1.1 | http2 | http2and3 | http3"
  type        = string
  default     = "http2and3"
  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "http_version must be http1.1, http2, http2and3, or http3."
  }
}

variable "price_class" {
  description = <<-EOT
    CloudFront edge location price class.
    PriceClass_All       = all edge locations (best performance globally)
    PriceClass_200       = US, Canada, Europe, Asia, Middle East, Africa
    PriceClass_100       = US, Canada, Europe only (cheapest)
  EOT
  type    = string
  default = "PriceClass_All"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "comment" {
  description = "Human-readable comment for the distribution."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Object CloudFront returns when the root URL is requested (e.g. index.html)."
  type        = string
  default     = null
}

variable "retain_on_delete" {
  description = "Disable the distribution instead of deleting it when destroying. Useful for zero-downtime migrations."
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "Wait for the distribution to reach Deployed status after create/update."
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "AWS WAF WebACL ARN (must be in us-east-1 for CloudFront scope) to associate with this distribution."
  type        = string
  default     = null
}

# ===========================================================================
# ALIASES & TLS CERTIFICATE
# ===========================================================================
variable "aliases" {
  description = "List of CNAMEs (alternate domain names) for this distribution."
  type        = list(string)
  default     = []
}

variable "viewer_certificate" {
  description = <<-EOT
    TLS certificate configuration.
      cloudfront_default_certificate - Use CloudFront's default *.cloudfront.net cert (true when no custom domain)
      acm_certificate_arn            - ACM certificate ARN (must be in us-east-1)
      minimum_protocol_version       - TLSv1.2_2021 | TLSv1.2_2019 | TLSv1.2_2018 | TLSv1_2016 | TLSv1
      ssl_support_method             - sni-only (recommended) | vip (dedicated IP, extra cost)
  EOT
  type = object({
    cloudfront_default_certificate = optional(bool, false)
    acm_certificate_arn            = optional(string, null)
    minimum_protocol_version       = optional(string, "TLSv1.2_2021")
    ssl_support_method             = optional(string, "sni-only")
  })
  default = {
    cloudfront_default_certificate = true
  }
}

# ===========================================================================
# ORIGINS
# ===========================================================================
variable "origins" {
  description = <<-EOT
    List of origin configurations.
    Each origin represents a backend server CloudFront fetches from.

    origin_id                    - Unique identifier (referenced by cache behaviors)
    domain_name                  - Origin domain name (API GW domain, ALB DNS, S3 bucket regional domain, custom)
    origin_path                  - Optional path prefix appended to requests (e.g. /v1)
    connection_attempts          - Number of connection attempts (1-3)
    connection_timeout           - Connection timeout in seconds (1-10)

    # Custom origin (API GW, ALB, any HTTP server)
    custom_origin_config:
      http_port                  - HTTP port (default 80)
      https_port                 - HTTPS port (default 443)
      origin_protocol_policy     - http-only | https-only | match-viewer
      origin_ssl_protocols       - List: TLSv1 | TLSv1.1 | TLSv1.2
      origin_keepalive_timeout   - Idle keepalive timeout (1-60s)
      origin_read_timeout        - Response timeout (4-60s)

    # S3 origin with Origin Access Control (recommended over OAI)
    s3_origin_config:
      origin_access_control_id   - OAC ID (use origin_access_controls variable to create)
      origin_access_identity     - Legacy OAI path (use OAC instead for new deployments)

    # Custom headers forwarded to origin
    custom_headers:              - list of { name, value }

    # Origin Shield (intermediate caching layer for latency-sensitive origins)
    origin_shield:
      enabled                    - Enable Origin Shield
      origin_shield_region       - AWS region for Origin Shield (closest to origin)

    # VPC origin (for private ALB / ECS / EC2 not internet-accessible)
    vpc_origin_config:
      vpc_origin_id              - VPC origin resource ID
      origin_ssl_protocols       - TLS versions for VPC origin
  EOT
  type = list(object({
    origin_id           = string
    domain_name         = string
    origin_path         = optional(string, null)
    connection_attempts = optional(number, 3)
    connection_timeout  = optional(number, 10)

    custom_origin_config = optional(object({
      http_port                = optional(number, 80)
      https_port               = optional(number, 443)
      origin_protocol_policy   = optional(string, "https-only")
      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
      origin_keepalive_timeout = optional(number, 5)
      origin_read_timeout      = optional(number, 30)
    }), null)

    s3_origin_config = optional(object({
      origin_access_control_id = optional(string, null)
      origin_access_identity   = optional(string, "")
    }), null)

    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])

    origin_shield = optional(object({
      enabled              = bool
      origin_shield_region = string
    }), null)

    vpc_origin_config = optional(object({
      vpc_origin_id        = string
      origin_ssl_protocols = optional(list(string), ["TLSv1.2"])
    }), null)
  }))
  default = []
}

# ===========================================================================
# ORIGIN GROUPS (failover)
# ===========================================================================
variable "origin_groups" {
  description = <<-EOT
    Origin groups for automatic failover between a primary and secondary origin.
    CloudFront fails over to the secondary when the primary returns configured status codes.

      origin_group_id             - Unique ID for the group
      primary_origin_id           - origin_id of the primary origin
      failover_origin_id          - origin_id of the failover origin
      failover_status_codes       - HTTP status codes that trigger failover (e.g. [500, 502, 503, 504])
  EOT
  type = list(object({
    origin_group_id       = string
    primary_origin_id     = string
    failover_origin_id    = string
    failover_status_codes = optional(list(number), [500, 502, 503, 504])
  }))
  default = []
}

# ===========================================================================
# ORIGIN ACCESS CONTROLS (OAC — for S3 private origins)
# ===========================================================================
variable "origin_access_controls" {
  description = <<-EOT
    Map of Origin Access Control configurations for S3 private bucket access.
    Preferred over legacy Origin Access Identity (OAI).

    Key = logical name, value:
      name                            - OAC name
      description                     - Description
      origin_access_control_origin_type - s3 | mediastore
      signing_behavior                - always | never | no-override
      signing_protocol                - sigv4
  EOT
  type = map(object({
    name                              = optional(string, null)
    description                       = optional(string, "")
    origin_access_control_origin_type = optional(string, "s3")
    signing_behavior                  = optional(string, "always")
    signing_protocol                  = optional(string, "sigv4")
  }))
  default = {}
}

# ===========================================================================
# DEFAULT CACHE BEHAVIOR
# ===========================================================================
variable "default_cache_behavior" {
  description = <<-EOT
    Default cache behavior applied to all paths not matched by ordered_cache_behaviors.

      target_origin_id          - origin_id or origin_group_id to route requests to
      allowed_methods           - HTTP methods CloudFront accepts and forwards
      cached_methods            - HTTP methods CloudFront caches responses for
      compress                  - Auto-compress responses (gzip/brotli)
      viewer_protocol_policy    - allow-all | redirect-to-https | https-only
      cache_policy_id           - Managed or custom cache policy ID
      origin_request_policy_id  - Managed or custom origin request policy ID
      response_headers_policy_id - Managed or custom response headers policy ID
      trusted_key_groups        - List of CloudFront key group IDs for signed URLs/cookies
      trusted_signers           - Legacy: list of AWS account numbers for signed URLs
      smooth_streaming          - Enable smooth streaming for Microsoft IIS
      field_level_encryption_id - Field-level encryption configuration ID
      function_associations     - CloudFront Functions (viewer-request / viewer-response)
      lambda_function_associations - Lambda@Edge associations
      min_ttl / default_ttl / max_ttl - TTL overrides (ignored when cache_policy_id is set)
      forwarded_values          - Legacy forwarding config (use cache/origin policies instead)
  EOT
  type = object({
    target_origin_id            = string
    allowed_methods             = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
    cached_methods              = optional(list(string), ["GET", "HEAD"])
    compress                    = optional(bool, true)
    viewer_protocol_policy      = optional(string, "redirect-to-https")
    cache_policy_id             = optional(string, null)
    origin_request_policy_id    = optional(string, null)
    response_headers_policy_id  = optional(string, null)
    trusted_key_groups          = optional(list(string), [])
    trusted_signers             = optional(list(string), [])
    smooth_streaming            = optional(bool, false)
    field_level_encryption_id   = optional(string, null)
    min_ttl                     = optional(number, 0)
    default_ttl                 = optional(number, 86400)
    max_ttl                     = optional(number, 31536000)

    function_associations = optional(list(object({
      event_type   = string # viewer-request | viewer-response
      function_arn = string
    })), [])

    lambda_function_associations = optional(list(object({
      event_type   = string # viewer-request | viewer-response | origin-request | origin-response
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])

    forwarded_values = optional(object({
      query_string            = optional(bool, false)
      query_string_cache_keys = optional(list(string), [])
      headers                 = optional(list(string), [])
      cookies_forward         = optional(string, "none")
      cookies_whitelisted     = optional(list(string), [])
    }), null)
  })
}

# ===========================================================================
# ORDERED CACHE BEHAVIORS (path-based routing)
# ===========================================================================
variable "ordered_cache_behaviors" {
  description = <<-EOT
    List of ordered cache behaviors for path-based routing. Evaluated before default_cache_behavior.
    Order matters — first match wins.
    All fields are the same as default_cache_behavior plus:
      path_pattern - CloudFront path pattern (e.g. /api/*, /static/*, /v1/payments*)
  EOT
  type = list(object({
    path_pattern                = string
    target_origin_id            = string
    allowed_methods             = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods              = optional(list(string), ["GET", "HEAD"])
    compress                    = optional(bool, true)
    viewer_protocol_policy      = optional(string, "redirect-to-https")
    cache_policy_id             = optional(string, null)
    origin_request_policy_id    = optional(string, null)
    response_headers_policy_id  = optional(string, null)
    trusted_key_groups          = optional(list(string), [])
    trusted_signers             = optional(list(string), [])
    smooth_streaming            = optional(bool, false)
    field_level_encryption_id   = optional(string, null)
    min_ttl                     = optional(number, 0)
    default_ttl                 = optional(number, 0)
    max_ttl                     = optional(number, 31536000)

    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])

    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])

    forwarded_values = optional(object({
      query_string            = optional(bool, true)
      query_string_cache_keys = optional(list(string), [])
      headers                 = optional(list(string), [])
      cookies_forward         = optional(string, "all")
      cookies_whitelisted     = optional(list(string), [])
    }), null)
  }))
  default = []
}

# ===========================================================================
# CUSTOM ERROR RESPONSES
# ===========================================================================
variable "custom_error_responses" {
  description = <<-EOT
    Map HTTP error codes to custom responses or origin error caching TTLs.
      error_code            - HTTP status code (4xx or 5xx)
      response_code         - HTTP status code CloudFront returns to viewers (e.g. 200)
      response_page_path    - Path to custom error page (e.g. /error.html)
      error_caching_min_ttl - Minimum seconds to cache this error response (default 300)
  EOT
  type = list(object({
    error_code            = number
    response_code         = optional(number, null)
    response_page_path    = optional(string, null)
    error_caching_min_ttl = optional(number, 300)
  }))
  default = []
}

# ===========================================================================
# GEO RESTRICTION
# ===========================================================================
variable "geo_restriction" {
  description = <<-EOT
    Geographic access restriction.
      restriction_type - none | whitelist | blacklist
      locations        - List of ISO 3166-1-alpha-2 country codes
  EOT
  type = object({
    restriction_type = optional(string, "none")
    locations        = optional(list(string), [])
  })
  default = {
    restriction_type = "none"
    locations        = []
  }
}

# ===========================================================================
# LOGGING
# ===========================================================================
variable "logging_config" {
  description = <<-EOT
    Access log configuration. Logs CloudFront viewer request/response details to S3.
      bucket          - S3 bucket domain name (e.g. my-logs.s3.amazonaws.com)
      prefix          - Optional log file prefix
      include_cookies - Include cookie data in access logs
  EOT
  type = object({
    bucket          = string
    prefix          = optional(string, "")
    include_cookies = optional(bool, false)
  })
  default = null
}

# ===========================================================================
# CLOUDFRONT FUNCTIONS
# ===========================================================================
variable "cloudfront_functions" {
  description = <<-EOT
    Map of CloudFront Functions to create (lightweight JS running at edge PoPs).
    Use for URL rewrites, header manipulation, auth token validation, A/B testing.

    Key = logical name:
      name    - Function name in CloudFront
      runtime - cloudfront-js-1.0 | cloudfront-js-2.0
      comment - Description
      code    - JavaScript source code string
      publish - Publish to LIVE stage (default true)
  EOT
  type = map(object({
    name    = string
    runtime = optional(string, "cloudfront-js-2.0")
    comment = optional(string, "")
    code    = string
    publish = optional(bool, true)
  }))
  default = {}
}

# ===========================================================================
# REAL-TIME LOG CONFIG
# ===========================================================================
variable "realtime_log_config" {
  description = <<-EOT
    Real-time log configuration for streaming CloudFront request logs to Kinesis.
      name             - Config name
      sampling_rate    - Percentage of requests to log (1-100)
      fields           - List of CloudFront log fields to include
      kinesis_stream_arn - Kinesis Data Stream ARN
      iam_role_arn       - IAM role ARN CloudFront uses to put records (auto-created when null)
  EOT
  type = object({
    name               = string
    sampling_rate      = optional(number, 100)
    fields             = optional(list(string), ["timestamp", "c-ip", "cs-uri-stem", "sc-status", "cs-method", "time-taken", "x-edge-location", "ssl-protocol"])
    kinesis_stream_arn = string
    iam_role_arn       = optional(string, null)
  })
  default = null
}
