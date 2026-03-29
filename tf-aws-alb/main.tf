# ---------------------------------------------------------------------------
# Managed Security Group (optional)
# ---------------------------------------------------------------------------
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = coalesce(var.security_group_name, "${local.name}-alb")
  description = "Managed by tf-aws-alb: HTTP/HTTPS inbound for ${local.name}"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = coalesce(var.security_group_name, "${local.name}-alb") })
}

resource "aws_vpc_security_group_ingress_rule" "http_ipv4" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = var.security_group_ingress_cidr_ipv4[0]
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from internet"
}

resource "aws_vpc_security_group_ingress_rule" "https_ipv4" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = var.security_group_ingress_cidr_ipv4[0]
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from internet"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound"
}

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------
resource "aws_lb" "this" {
  name                             = local.name
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  security_groups                  = var.create_security_group ? concat([aws_security_group.this[0].id], var.security_groups) : var.security_groups
  subnets                          = var.subnets
  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.load_balancer_type == "application" ? var.enable_http2 : null
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.load_balancer_type == "application" ? var.idle_timeout : null
  drop_invalid_header_fields       = var.load_balancer_type == "application" ? var.drop_invalid_header_fields : null
  preserve_host_header             = var.load_balancer_type == "application" ? var.preserve_host_header : null
  ip_address_type                  = var.ip_address_type
  desync_mitigation_mode           = var.load_balancer_type == "application" ? var.desync_mitigation_mode : null
  xff_header_processing_mode       = var.load_balancer_type == "application" ? var.xff_header_processing_mode : null
  client_keep_alive                = var.load_balancer_type == "application" ? var.client_keep_alive : null

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  dynamic "connection_logs" {
    for_each = var.connection_logs_enabled && var.load_balancer_type == "application" ? [1] : []
    content {
      bucket  = var.connection_logs_bucket
      prefix  = var.connection_logs_prefix
      enabled = true
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# WAF Association
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "this" {
  count        = var.web_acl_arn != null ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.web_acl_arn
}

# ---------------------------------------------------------------------------
# Target Groups
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = "${local.name}-${each.key}"
  port                 = each.value.target_type == "lambda" ? null : each.value.port
  protocol             = each.value.target_type == "lambda" ? null : each.value.protocol
  protocol_version     = each.value.target_type == "lambda" ? null : each.value.protocol_version
  target_type          = each.value.target_type
  vpc_id               = each.value.target_type == "lambda" ? null : coalesce(each.value.vpc_id, var.vpc_id)
  deregistration_delay = each.value.deregistration_delay

  load_balancing_algorithm_type     = contains(["HTTP", "HTTPS"], coalesce(each.value.protocol, "HTTP")) ? each.value.load_balancing_algorithm_type : null
  load_balancing_anomaly_mitigation = each.value.load_balancing_algorithm_type == "weighted_random" ? each.value.load_balancing_anomaly_mitigation : null
  slow_start                        = contains(["HTTP", "HTTPS"], coalesce(each.value.protocol, "HTTP")) ? each.value.slow_start : null

  lambda_multi_value_headers_enabled = each.value.target_type == "lambda" ? each.value.lambda_multi_value_headers_enabled : null
  connection_termination             = each.value.connection_termination

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      matcher             = health_check.value.matcher
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.type != "source_ip" ? stickiness.value.cookie_duration : null
      cookie_name     = stickiness.value.type == "app_cookie" ? stickiness.value.cookie_name : null
    }
  }

  tags = merge(local.tags, { TargetGroup = each.key })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Target Group Attachments
# (instances, IP addresses, Lambda ARNs, or child ALBs)
# ---------------------------------------------------------------------------
resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for item in flatten([
      for tg_key, tg in var.target_groups : [
        for i, att in tg.attachments : {
          key               = "${tg_key}-${i}"
          target_group_key  = tg_key
          target_id         = att.target_id
          port              = att.port
          availability_zone = att.availability_zone
        }
      ]
    ]) : item.key => item
  }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = each.value.port
  availability_zone = each.value.availability_zone
}

# ---------------------------------------------------------------------------
# Listeners
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  # TLS-only attributes — ignored for HTTP/TCP
  ssl_policy      = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.ssl_policy : null
  certificate_arn = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.certificate_arn : null
  alpn_policy     = each.value.protocol == "TLS" ? each.value.alpn_policy : null

  # Mutual TLS (mTLS) — HTTPS only
  dynamic "mutual_authentication" {
    for_each = each.value.mutual_authentication != null && each.value.protocol == "HTTPS" ? [each.value.mutual_authentication] : []
    content {
      mode                             = mutual_authentication.value.mode
      trust_store_arn                  = mutual_authentication.value.trust_store_arn
      ignore_client_certificate_expiry = mutual_authentication.value.ignore_client_certificate_expiry
    }
  }

  default_action {
    type = each.value.default_action.type

    # Simple forward to a single target group
    target_group_arn = (
      each.value.default_action.type == "forward" &&
      each.value.default_action.target_group_key != null &&
      each.value.default_action.forward == null
      ? aws_lb_target_group.this[each.value.default_action.target_group_key].arn
      : null
    )

    # Weighted forward to multiple target groups
    dynamic "forward" {
      for_each = each.value.default_action.type == "forward" && each.value.default_action.forward != null ? [each.value.default_action.forward] : []
      content {
        dynamic "target_group" {
          for_each = forward.value.target_groups
          content {
            arn    = aws_lb_target_group.this[target_group.value.target_group_key].arn
            weight = target_group.value.weight
          }
        }
        dynamic "stickiness" {
          for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
          content {
            enabled  = stickiness.value.enabled
            duration = stickiness.value.duration
          }
        }
      }
    }

    dynamic "redirect" {
      for_each = each.value.default_action.type == "redirect" && each.value.default_action.redirect != null ? [each.value.default_action.redirect] : []
      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
        host        = redirect.value.host
        path        = redirect.value.path
        query       = redirect.value.query
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.default_action.type == "fixed-response" && each.value.default_action.fixed_response != null ? [each.value.default_action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }

  tags = merge(local.tags, { Listener = "${each.value.protocol}/${each.value.port}" })
}

# Additional certificates for SNI on HTTPS listeners
resource "aws_lb_listener_certificate" "this" {
  for_each = {
    for item in flatten([
      for lk, lv in var.listeners : [
        for cert_arn in lv.additional_certificate_arns : {
          key             = "${lk}-${cert_arn}"
          listener_key    = lk
          certificate_arn = cert_arn
        }
      ]
    ]) : item.key => item
  }

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

# ---------------------------------------------------------------------------
# Listener Rules (path/host/header/method/source-IP/query routing)
# ---------------------------------------------------------------------------
resource "aws_lb_listener_rule" "this" {
  for_each = {
    for item in flatten([
      for lk, lv in var.listeners : [
        for rule in lv.rules : {
          key          = "${lk}-${rule.priority}"
          listener_key = lk
          rule         = rule
        }
      ]
    ]) : item.key => item
  }

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.rule.priority

  # ── Conditions ───────────────────────────────────────────────────────────
  dynamic "condition" {
    for_each = [
      for c in each.value.rule.conditions : c if c.path_pattern != null
    ]
    content {
      path_pattern { values = condition.value.path_pattern }
    }
  }

  dynamic "condition" {
    for_each = [
      for c in each.value.rule.conditions : c if c.host_header != null
    ]
    content {
      host_header { values = condition.value.host_header }
    }
  }

  dynamic "condition" {
    for_each = [
      for c in each.value.rule.conditions : c if c.http_method != null
    ]
    content {
      http_request_method { values = condition.value.http_method }
    }
  }

  dynamic "condition" {
    for_each = [
      for c in each.value.rule.conditions : c if c.source_ip != null
    ]
    content {
      source_ip { values = condition.value.source_ip }
    }
  }

  dynamic "condition" {
    for_each = [
      for c in each.value.rule.conditions : c if c.http_header != null
    ]
    content {
      http_header {
        http_header_name = condition.value.http_header.header_name
        values           = condition.value.http_header.values
      }
    }
  }

  dynamic "condition" {
    for_each = [
      for c in each.value.rule.conditions : c if c.query_string != null
    ]
    content {
      dynamic "query_string" {
        for_each = condition.value.query_string
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }
    }
  }

  # ── Action ────────────────────────────────────────────────────────────────
  action {
    type = each.value.rule.action.type

    target_group_arn = (
      each.value.rule.action.type == "forward" &&
      each.value.rule.action.target_group_key != null &&
      each.value.rule.action.forward == null
      ? aws_lb_target_group.this[each.value.rule.action.target_group_key].arn
      : null
    )

    dynamic "forward" {
      for_each = each.value.rule.action.type == "forward" && each.value.rule.action.forward != null ? [each.value.rule.action.forward] : []
      content {
        dynamic "target_group" {
          for_each = forward.value.target_groups
          content {
            arn    = aws_lb_target_group.this[target_group.value.target_group_key].arn
            weight = target_group.value.weight
          }
        }
        dynamic "stickiness" {
          for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
          content {
            enabled  = stickiness.value.enabled
            duration = stickiness.value.duration
          }
        }
      }
    }

    dynamic "redirect" {
      for_each = each.value.rule.action.type == "redirect" && each.value.rule.action.redirect != null ? [each.value.rule.action.redirect] : []
      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
        host        = redirect.value.host
        path        = redirect.value.path
        query       = redirect.value.query
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.rule.action.type == "fixed-response" && each.value.rule.action.fixed_response != null ? [each.value.rule.action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }

  tags = merge(local.tags, { ListenerRule = each.key })
}
