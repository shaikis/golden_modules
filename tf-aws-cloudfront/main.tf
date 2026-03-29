# ===========================================================================
# ORIGIN ACCESS CONTROLS (OAC) — S3 private bucket access (preferred over OAI)
# ===========================================================================
resource "aws_cloudfront_origin_access_control" "this" {
  for_each = var.origin_access_controls

  name                              = coalesce(each.value.name, "${local.name}-${each.key}")
  description                       = each.value.description
  origin_access_control_origin_type = each.value.origin_access_control_origin_type
  signing_behavior                  = each.value.signing_behavior
  signing_protocol                  = each.value.signing_protocol
}

# ===========================================================================
# CLOUDFRONT FUNCTIONS (lightweight JS at edge PoPs)
# ===========================================================================
resource "aws_cloudfront_function" "this" {
  for_each = var.cloudfront_functions

  name    = each.value.name
  runtime = each.value.runtime
  comment = each.value.comment
  publish = each.value.publish
  code    = each.value.code
}

# ===========================================================================
# REAL-TIME LOG CONFIGURATION (Kinesis streaming of viewer request data)
# ===========================================================================
resource "aws_iam_role" "realtime_log" {
  count = var.realtime_log_config != null && var.realtime_log_config.iam_role_arn == null ? 1 : 0
  name  = "${local.name}-cf-realtime-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "realtime_log" {
  count = var.realtime_log_config != null && var.realtime_log_config.iam_role_arn == null ? 1 : 0
  name  = "kinesis-put-records"
  role  = aws_iam_role.realtime_log[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kinesis:PutRecord", "kinesis:PutRecords"]
      Resource = var.realtime_log_config.kinesis_stream_arn
    }]
  })
}

resource "aws_cloudfront_realtime_log_config" "this" {
  count         = var.realtime_log_config != null ? 1 : 0
  name          = var.realtime_log_config.name
  sampling_rate = var.realtime_log_config.sampling_rate
  fields        = var.realtime_log_config.fields

  endpoint {
    stream_type = "Kinesis"
    kinesis_stream_config {
      role_arn   = coalesce(var.realtime_log_config.iam_role_arn, try(aws_iam_role.realtime_log[0].arn, null))
      stream_arn = var.realtime_log_config.kinesis_stream_arn
    }
  }
}

# ===========================================================================
# CLOUDFRONT DISTRIBUTION
# ===========================================================================
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  http_version        = var.http_version
  price_class         = var.price_class
  comment             = coalesce(var.comment, local.name)
  default_root_object = var.default_root_object
  aliases             = var.aliases
  web_acl_id          = var.web_acl_id
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment

  # ─── Origins ──────────────────────────────────────────────────────────────
  dynamic "origin" {
    for_each = var.origins
    content {
      origin_id   = origin.value.origin_id
      domain_name = origin.value.domain_name
      origin_path = origin.value.origin_path

      connection_attempts = origin.value.connection_attempts
      connection_timeout  = origin.value.connection_timeout

      # OAC (modern S3 access — preferred)
      origin_access_control_id = (
        origin.value.s3_origin_config != null &&
        origin.value.s3_origin_config.origin_access_control_id != null
        ? origin.value.s3_origin_config.origin_access_control_id
        : null
      )

      # Custom HTTP origin (API GW, ALB, custom server)
      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []
        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
        }
      }

      # Legacy OAI (for backwards compatibility — use OAC for new deployments)
      dynamic "s3_origin_config" {
        for_each = (
          origin.value.s3_origin_config != null &&
          origin.value.s3_origin_config.origin_access_identity != null &&
          origin.value.s3_origin_config.origin_access_identity != ""
          ? [origin.value.s3_origin_config] : []
        )
        content {
          origin_access_identity = s3_origin_config.value.origin_access_identity
        }
      }

      # Custom origin secret header (prevents direct-to-origin access bypassing CloudFront)
      dynamic "custom_header" {
        for_each = origin.value.custom_headers
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      # Origin Shield (reduces origin load for high-traffic origins)
      dynamic "origin_shield" {
        for_each = origin.value.origin_shield != null ? [origin.value.origin_shield] : []
        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }

      # VPC origin (private ALB/ECS not internet-accessible)
      dynamic "vpc_origin_config" {
        for_each = origin.value.vpc_origin_config != null ? [origin.value.vpc_origin_config] : []
        content {
          vpc_origin_id        = vpc_origin_config.value.vpc_origin_id
          origin_ssl_protocols = vpc_origin_config.value.origin_ssl_protocols
        }
      }
    }
  }

  # ─── Origin Groups (automatic failover) ───────────────────────────────────
  dynamic "origin_group" {
    for_each = var.origin_groups
    content {
      origin_id = origin_group.value.origin_group_id

      failover_criteria {
        status_codes = origin_group.value.failover_status_codes
      }

      member { origin_id = origin_group.value.primary_origin_id }
      member { origin_id = origin_group.value.failover_origin_id }
    }
  }

  # ─── Default Cache Behavior ───────────────────────────────────────────────
  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    compress               = var.default_cache_behavior.compress
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy

    # Modern managed/custom policies (preferred over legacy forwarded_values)
    cache_policy_id            = var.default_cache_behavior.cache_policy_id
    origin_request_policy_id   = var.default_cache_behavior.origin_request_policy_id
    response_headers_policy_id = var.default_cache_behavior.response_headers_policy_id

    trusted_key_groups        = var.default_cache_behavior.trusted_key_groups
    trusted_signers           = var.default_cache_behavior.trusted_signers
    smooth_streaming          = var.default_cache_behavior.smooth_streaming
    field_level_encryption_id = var.default_cache_behavior.field_level_encryption_id

    # TTL controls — only set when NOT using a cache policy (cache policies override these)
    min_ttl     = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.min_ttl : null
    default_ttl = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.default_ttl : null
    max_ttl     = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.max_ttl : null

    # Real-time log config (Kinesis stream)
    realtime_log_config_arn = try(aws_cloudfront_realtime_log_config.this[0].arn, null)

    # Legacy forwarded values (only used when cache_policy_id is null)
    dynamic "forwarded_values" {
      for_each = (
        var.default_cache_behavior.forwarded_values != null &&
        var.default_cache_behavior.cache_policy_id == null
        ? [var.default_cache_behavior.forwarded_values] : []
      )
      content {
        query_string            = forwarded_values.value.query_string
        query_string_cache_keys = forwarded_values.value.query_string_cache_keys
        headers                 = forwarded_values.value.headers
        cookies {
          forward           = forwarded_values.value.cookies_forward
          whitelisted_names = forwarded_values.value.cookies_whitelisted
        }
      }
    }

    # CloudFront Functions (viewer-request / viewer-response — sub-ms execution)
    dynamic "function_association" {
      for_each = var.default_cache_behavior.function_associations
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }

    # Lambda@Edge (origin-request / origin-response / viewer-request / viewer-response)
    dynamic "lambda_function_association" {
      for_each = var.default_cache_behavior.lambda_function_associations
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }
  }

  # ─── Ordered Cache Behaviors (path-based routing — first match wins) ──────
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      compress               = ordered_cache_behavior.value.compress
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id

      trusted_key_groups        = ordered_cache_behavior.value.trusted_key_groups
      trusted_signers           = ordered_cache_behavior.value.trusted_signers
      smooth_streaming          = ordered_cache_behavior.value.smooth_streaming
      field_level_encryption_id = ordered_cache_behavior.value.field_level_encryption_id

      min_ttl     = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.min_ttl : null
      default_ttl = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.default_ttl : null
      max_ttl     = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.max_ttl : null

      dynamic "forwarded_values" {
        for_each = (
          ordered_cache_behavior.value.forwarded_values != null &&
          ordered_cache_behavior.value.cache_policy_id == null
          ? [ordered_cache_behavior.value.forwarded_values] : []
        )
        content {
          query_string            = forwarded_values.value.query_string
          query_string_cache_keys = forwarded_values.value.query_string_cache_keys
          headers                 = forwarded_values.value.headers
          cookies {
            forward           = forwarded_values.value.cookies_forward
            whitelisted_names = forwarded_values.value.cookies_whitelisted
          }
        }
      }

      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.function_associations
        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_associations
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lambda_function_association.value.include_body
        }
      }
    }
  }

  # ─── Custom Error Responses ────────────────────────────────────────────────
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # ─── Geographic Restriction ────────────────────────────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction.restriction_type
      locations        = var.geo_restriction.locations
    }
  }

  # ─── TLS / Viewer Certificate ─────────────────────────────────────────────
  viewer_certificate {
    # Use CloudFront default cert when no custom domain
    cloudfront_default_certificate = var.viewer_certificate.acm_certificate_arn == null ? true : false
    # Custom domain: ACM cert (must be in us-east-1 for CloudFront)
    acm_certificate_arn      = var.viewer_certificate.acm_certificate_arn
    minimum_protocol_version = var.viewer_certificate.acm_certificate_arn != null ? var.viewer_certificate.minimum_protocol_version : null
    ssl_support_method       = var.viewer_certificate.acm_certificate_arn != null ? var.viewer_certificate.ssl_support_method : null
  }

  # ─── S3 Access Logging ─────────────────────────────────────────────────────
  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  tags = local.tags

  lifecycle {
    # Prevent brief downtime during certificate rotation
    create_before_destroy = true
  }
}
