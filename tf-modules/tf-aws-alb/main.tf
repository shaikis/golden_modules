# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------
resource "aws_lb" "this" {
  name                             = local.name
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  security_groups                  = var.security_groups
  subnets                          = var.subnets
  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.idle_timeout
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  preserve_host_header             = var.preserve_host_header
  ip_address_type                  = var.ip_address_type

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# WAF association
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
  port                 = each.value.port
  protocol             = each.value.protocol
  protocol_version     = each.value.protocol_version
  target_type          = each.value.target_type
  vpc_id               = coalesce(each.value.vpc_id, var.vpc_id)
  deregistration_delay = each.value.deregistration_delay

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
      cookie_duration = stickiness.value.cookie_duration
    }
  }

  tags = merge(local.tags, { TargetGroup = each.key })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Listeners
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.ssl_policy : null
  certificate_arn   = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.certificate_arn : null

  default_action {
    type = each.value.default_action.type
    target_group_arn = (
      each.value.default_action.type == "forward" && each.value.default_action.target_group_key != null
      ? aws_lb_target_group.this[each.value.default_action.target_group_key].arn
      : null
    )

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

# Additional certificates on HTTPS listeners
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
