# ===========================================================================
# IP SETS
# ===========================================================================
resource "aws_wafv2_ip_set" "this" {
  for_each = var.ip_sets

  name               = coalesce(each.value.name, "${local.name}-${each.key}")
  description        = each.value.description
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses

  tags = local.tags
}

# ===========================================================================
# REGEX PATTERN SETS
# ===========================================================================
resource "aws_wafv2_regex_pattern_set" "this" {
  for_each = var.regex_pattern_sets

  name        = coalesce(each.value.name, "${local.name}-${each.key}")
  description = each.value.description
  scope       = var.scope

  dynamic "regular_expression" {
    for_each = each.value.patterns
    content {
      regex_string = regular_expression.value
    }
  }

  tags = local.tags
}

# ===========================================================================
# WebACL
# ===========================================================================
resource "aws_wafv2_web_acl" "this" {
  name        = local.name
  description = var.description
  scope       = var.scope

  dynamic "token_domains" {
    for_each = length(var.token_domains) > 0 ? [var.token_domains] : []
    content {
      token_domains = token_domains.value
    }
  }

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    metric_name                = coalesce(var.metric_name, local.name)
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  # -------------------------------------------------------------------------
  # Managed Rule Groups
  # -------------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "override_action" {
        for_each = [rule.value.override_action]
        content {
          dynamic "none" {
            for_each = override_action.value == "none" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = override_action.value == "count" ? [1] : []
            content {}
          }
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
          version     = rule.value.version

          dynamic "excluded_rule" {
            for_each = rule.value.excluded_rules
            content {
              name = excluded_rule.value
            }
          }

          dynamic "rule_action_override" {
            for_each = rule.value.rule_action_overrides
            content {
              name = rule_action_override.value.name
              action_to_use {
                dynamic "allow"     { for_each = rule_action_override.value.action == "allow"     ? [1] : []; content {} }
                dynamic "block"     { for_each = rule_action_override.value.action == "block"     ? [1] : []; content {} }
                dynamic "count"     { for_each = rule_action_override.value.action == "count"     ? [1] : []; content {} }
                dynamic "captcha"   { for_each = rule_action_override.value.action == "captcha"   ? [1] : []; content {} }
                dynamic "challenge" { for_each = rule_action_override.value.action == "challenge" ? [1] : []; content {} }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = "${local.name}-${rule.value.name}"
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  # -------------------------------------------------------------------------
  # Rate-Based Rules
  # -------------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.rate_based_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "block"     { for_each = rule.value.action == "block"     ? [1] : []; content {} }
        dynamic "count"     { for_each = rule.value.action == "count"     ? [1] : []; content {} }
        dynamic "captcha"   { for_each = rule.value.action == "captcha"   ? [1] : []; content {} }
        dynamic "challenge" { for_each = rule.value.action == "challenge" ? [1] : []; content {} }
      }

      statement {
        rate_based_statement {
          limit              = rule.value.limit
          aggregate_key_type = rule.value.aggregate_key_type

          dynamic "forwarded_ip_config" {
            for_each = rule.value.forwarded_ip_config != null ? [rule.value.forwarded_ip_config] : []
            content {
              header_name       = forwarded_ip_config.value.header_name
              fallback_behavior = forwarded_ip_config.value.fallback_behavior
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = "${local.name}-${rule.value.name}"
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  # -------------------------------------------------------------------------
  # IP Set Rules
  # -------------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.ip_set_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow"     { for_each = rule.value.action == "allow"     ? [1] : []; content {} }
        dynamic "block"     { for_each = rule.value.action == "block"     ? [1] : []; content {} }
        dynamic "count"     { for_each = rule.value.action == "count"     ? [1] : []; content {} }
        dynamic "captcha"   { for_each = rule.value.action == "captcha"   ? [1] : []; content {} }
        dynamic "challenge" { for_each = rule.value.action == "challenge" ? [1] : []; content {} }
      }

      statement {
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.negated == false ? [1] : []
          content {
            arn = coalesce(
              rule.value.ip_set_arn,
              try(aws_wafv2_ip_set.this[rule.value.ip_set_key].arn, null)
            )
            dynamic "ip_set_forwarded_ip_config" {
              for_each = rule.value.forwarded_ip_config != null ? [rule.value.forwarded_ip_config] : []
              content {
                header_name       = ip_set_forwarded_ip_config.value.header_name
                fallback_behavior = ip_set_forwarded_ip_config.value.fallback_behavior
                position          = "FIRST"
              }
            }
          }
        }

        dynamic "not_statement" {
          for_each = rule.value.negated == true ? [1] : []
          content {
            statement {
              ip_set_reference_statement {
                arn = coalesce(
                  rule.value.ip_set_arn,
                  try(aws_wafv2_ip_set.this[rule.value.ip_set_key].arn, null)
                )
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = "${local.name}-${rule.value.name}"
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  # -------------------------------------------------------------------------
  # Geo Match Rules
  # -------------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.geo_match_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow"     { for_each = rule.value.action == "allow"     ? [1] : []; content {} }
        dynamic "block"     { for_each = rule.value.action == "block"     ? [1] : []; content {} }
        dynamic "count"     { for_each = rule.value.action == "count"     ? [1] : []; content {} }
        dynamic "captcha"   { for_each = rule.value.action == "captcha"   ? [1] : []; content {} }
        dynamic "challenge" { for_each = rule.value.action == "challenge" ? [1] : []; content {} }
      }

      statement {
        dynamic "geo_match_statement" {
          for_each = rule.value.negated == false ? [1] : []
          content {
            country_codes = rule.value.country_codes
            dynamic "forwarded_ip_config" {
              for_each = rule.value.forwarded_ip_config != null ? [rule.value.forwarded_ip_config] : []
              content {
                header_name       = forwarded_ip_config.value.header_name
                fallback_behavior = forwarded_ip_config.value.fallback_behavior
              }
            }
          }
        }

        dynamic "not_statement" {
          for_each = rule.value.negated == true ? [1] : []
          content {
            statement {
              geo_match_statement {
                country_codes = rule.value.country_codes
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = "${local.name}-${rule.value.name}"
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  # -------------------------------------------------------------------------
  # Custom Rules (byte match, sqli, xss, size constraint, regex)
  # -------------------------------------------------------------------------
  dynamic "rule" {
    for_each = var.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow"     { for_each = rule.value.action == "allow"     ? [1] : []; content {} }
        dynamic "block"     { for_each = rule.value.action == "block"     ? [1] : []; content {} }
        dynamic "count"     { for_each = rule.value.action == "count"     ? [1] : []; content {} }
        dynamic "captcha"   { for_each = rule.value.action == "captcha"   ? [1] : []; content {} }
        dynamic "challenge" { for_each = rule.value.action == "challenge" ? [1] : []; content {} }
      }

      statement {
        # Byte match
        dynamic "byte_match_statement" {
          for_each = rule.value.byte_match_statement != null ? [rule.value.byte_match_statement] : []
          content {
            search_string         = byte_match_statement.value.search_string
            positional_constraint = byte_match_statement.value.positional_constraint
            field_to_match {
              dynamic "all_query_arguments" { for_each = byte_match_statement.value.field_to_match_type == "ALL_QUERY_ARGS" ? [1] : []; content {} }
              dynamic "body"               { for_each = byte_match_statement.value.field_to_match_type == "BODY"           ? [1] : []; content {} }
              dynamic "method"             { for_each = byte_match_statement.value.field_to_match_type == "METHOD"         ? [1] : []; content {} }
              dynamic "query_string"       { for_each = byte_match_statement.value.field_to_match_type == "QUERY_STRING"   ? [1] : []; content {} }
              dynamic "uri_path"           { for_each = byte_match_statement.value.field_to_match_type == "URI_PATH"       ? [1] : []; content {} }
              dynamic "single_header" {
                for_each = byte_match_statement.value.field_to_match_type == "SINGLE_HEADER" ? [1] : []
                content { name = lower(byte_match_statement.value.header_name) }
              }
            }
            dynamic "text_transformation" {
              for_each = byte_match_statement.value.text_transformations
              content {
                priority = index(byte_match_statement.value.text_transformations, text_transformation.value)
                type     = text_transformation.value
              }
            }
          }
        }

        # SQLi
        dynamic "sqli_match_statement" {
          for_each = rule.value.sqli_match_statement != null ? [rule.value.sqli_match_statement] : []
          content {
            field_to_match {
              dynamic "all_query_arguments" { for_each = sqli_match_statement.value.field_to_match_type == "ALL_QUERY_ARGS" ? [1] : []; content {} }
              dynamic "body"               { for_each = sqli_match_statement.value.field_to_match_type == "BODY"           ? [1] : []; content {} }
              dynamic "query_string"       { for_each = sqli_match_statement.value.field_to_match_type == "QUERY_STRING"   ? [1] : []; content {} }
              dynamic "uri_path"           { for_each = sqli_match_statement.value.field_to_match_type == "URI_PATH"       ? [1] : []; content {} }
              dynamic "single_header" {
                for_each = sqli_match_statement.value.field_to_match_type == "SINGLE_HEADER" ? [1] : []
                content { name = lower(sqli_match_statement.value.header_name) }
              }
            }
            dynamic "text_transformation" {
              for_each = sqli_match_statement.value.text_transformations
              content {
                priority = index(sqli_match_statement.value.text_transformations, text_transformation.value)
                type     = text_transformation.value
              }
            }
          }
        }

        # XSS
        dynamic "xss_match_statement" {
          for_each = rule.value.xss_match_statement != null ? [rule.value.xss_match_statement] : []
          content {
            field_to_match {
              dynamic "all_query_arguments" { for_each = xss_match_statement.value.field_to_match_type == "ALL_QUERY_ARGS" ? [1] : []; content {} }
              dynamic "body"               { for_each = xss_match_statement.value.field_to_match_type == "BODY"           ? [1] : []; content {} }
              dynamic "query_string"       { for_each = xss_match_statement.value.field_to_match_type == "QUERY_STRING"   ? [1] : []; content {} }
              dynamic "uri_path"           { for_each = xss_match_statement.value.field_to_match_type == "URI_PATH"       ? [1] : []; content {} }
              dynamic "single_header" {
                for_each = xss_match_statement.value.field_to_match_type == "SINGLE_HEADER" ? [1] : []
                content { name = lower(xss_match_statement.value.header_name) }
              }
            }
            dynamic "text_transformation" {
              for_each = xss_match_statement.value.text_transformations
              content {
                priority = index(xss_match_statement.value.text_transformations, text_transformation.value)
                type     = text_transformation.value
              }
            }
          }
        }

        # Size constraint
        dynamic "size_constraint_statement" {
          for_each = rule.value.size_constraint_statement != null ? [rule.value.size_constraint_statement] : []
          content {
            comparison_operator = size_constraint_statement.value.comparison_operator
            size                = size_constraint_statement.value.size
            field_to_match {
              dynamic "body"         { for_each = size_constraint_statement.value.field_to_match_type == "BODY"         ? [1] : []; content {} }
              dynamic "query_string" { for_each = size_constraint_statement.value.field_to_match_type == "QUERY_STRING" ? [1] : []; content {} }
              dynamic "uri_path"     { for_each = size_constraint_statement.value.field_to_match_type == "URI_PATH"     ? [1] : []; content {} }
              dynamic "single_header" {
                for_each = size_constraint_statement.value.field_to_match_type == "SINGLE_HEADER" ? [1] : []
                content { name = lower(size_constraint_statement.value.header_name) }
              }
            }
            dynamic "text_transformation" {
              for_each = size_constraint_statement.value.text_transformations
              content {
                priority = index(size_constraint_statement.value.text_transformations, text_transformation.value)
                type     = text_transformation.value
              }
            }
          }
        }

        # Regex pattern set
        dynamic "regex_pattern_set_reference_statement" {
          for_each = rule.value.regex_pattern_set_statement != null ? [rule.value.regex_pattern_set_statement] : []
          content {
            arn = aws_wafv2_regex_pattern_set.this[regex_pattern_set_reference_statement.value.regex_pattern_set_key].arn
            field_to_match {
              dynamic "all_query_arguments" { for_each = regex_pattern_set_reference_statement.value.field_to_match_type == "ALL_QUERY_ARGS" ? [1] : []; content {} }
              dynamic "body"               { for_each = regex_pattern_set_reference_statement.value.field_to_match_type == "BODY"           ? [1] : []; content {} }
              dynamic "query_string"       { for_each = regex_pattern_set_reference_statement.value.field_to_match_type == "QUERY_STRING"   ? [1] : []; content {} }
              dynamic "uri_path"           { for_each = regex_pattern_set_reference_statement.value.field_to_match_type == "URI_PATH"       ? [1] : []; content {} }
              dynamic "single_header" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match_type == "SINGLE_HEADER" ? [1] : []
                content { name = lower(regex_pattern_set_reference_statement.value.header_name) }
              }
            }
            dynamic "text_transformation" {
              for_each = regex_pattern_set_reference_statement.value.text_transformations
              content {
                priority = index(regex_pattern_set_reference_statement.value.text_transformations, text_transformation.value)
                type     = text_transformation.value
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = "${local.name}-${rule.value.name}"
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  tags = local.tags
}

# ===========================================================================
# LOGGING CONFIGURATION
# ===========================================================================
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.logging_config != null ? 1 : 0
  log_destination_configs = var.logging_config.log_destination_arns
  resource_arn            = aws_wafv2_web_acl.this.arn

  dynamic "redacted_fields" {
    for_each = var.logging_config.redacted_fields
    content {
      dynamic "single_header" {
        for_each = redacted_fields.value.type == "SINGLE_HEADER" ? [1] : []
        content { name = lower(redacted_fields.value.header_name) }
      }
      dynamic "method"       { for_each = redacted_fields.value.type == "METHOD"       ? [1] : []; content {} }
      dynamic "query_string" { for_each = redacted_fields.value.type == "QUERY_STRING" ? [1] : []; content {} }
      dynamic "uri_path"     { for_each = redacted_fields.value.type == "URI_PATH"     ? [1] : []; content {} }
      dynamic "body"         { for_each = redacted_fields.value.type == "BODY"         ? [1] : []; content {} }
    }
  }

  dynamic "logging_filter" {
    for_each = length(var.logging_config.filter_conditions) > 0 ? [1] : []
    content {
      default_behavior = "DROP"
      dynamic "filter" {
        for_each = var.logging_config.filter_conditions
        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement
          dynamic "condition" {
            for_each = filter.value.conditions
            content {
              action_condition {
                action = condition.value.action_condition
              }
            }
          }
        }
      }
    }
  }
}

# ===========================================================================
# RESOURCE ASSOCIATIONS (REGIONAL scope only)
# ===========================================================================
resource "aws_wafv2_web_acl_association" "this" {
  for_each     = var.scope == "REGIONAL" ? toset(var.resource_arns) : toset([])
  web_acl_arn  = aws_wafv2_web_acl.this.arn
  resource_arn = each.value
}
