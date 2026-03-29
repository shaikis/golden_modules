# ===========================================================================
# ARC CLUSTER
# Global 5-node infrastructure for routing control state management.
# Survives full regional failures — uses Raft consensus across 5 zones globally.
# ===========================================================================
resource "aws_route53recoverycontrolconfig_cluster" "this" {
  count = var.create_cluster ? 1 : 0
  name  = local.name
}

locals {
  cluster_arn = var.create_cluster ? aws_route53recoverycontrolconfig_cluster.this[0].arn : var.cluster_arn
}

# ===========================================================================
# CONTROL PANELS
# ===========================================================================
resource "aws_route53recoverycontrolconfig_control_panel" "this" {
  for_each    = var.control_panels
  cluster_arn = local.cluster_arn
  name        = coalesce(each.value.name, "${local.name}-${each.key}")
}

# ===========================================================================
# ROUTING CONTROLS
# ===========================================================================
resource "aws_route53recoverycontrolconfig_routing_control" "this" {
  for_each          = var.routing_controls
  cluster_arn       = local.cluster_arn
  control_panel_arn = aws_route53recoverycontrolconfig_control_panel.this[each.value.control_panel_key].arn
  name              = coalesce(each.value.name, "${local.name}-${each.key}")
}

# ===========================================================================
# SAFETY RULES — ASSERTION (minimum cells must stay on)
# ===========================================================================
resource "aws_route53recoverycontrolconfig_safety_rule" "assertion" {
  for_each = {
    for k, v in var.safety_rules : k => v
    if v.type == "ASSERTION"
  }

  name              = each.value.name
  control_panel_arn = aws_route53recoverycontrolconfig_control_panel.this[each.value.control_panel_key].arn
  wait_period_ms    = each.value.wait_period_ms

  asserted_controls = [
    for rc_key in each.value.asserted_controls :
    aws_route53recoverycontrolconfig_routing_control.this[rc_key].arn
  ]

  rule_config {
    inverted  = each.value.assertion_rule.inverted
    threshold = each.value.assertion_rule.threshold
    type      = each.value.assertion_rule.type
  }
}

# ===========================================================================
# SAFETY RULES — GATING (gate control must be ON before target can change)
# ===========================================================================
resource "aws_route53recoverycontrolconfig_safety_rule" "gating" {
  for_each = {
    for k, v in var.safety_rules : k => v
    if v.type == "GATING"
  }

  name              = each.value.name
  control_panel_arn = aws_route53recoverycontrolconfig_control_panel.this[each.value.control_panel_key].arn
  wait_period_ms    = each.value.wait_period_ms

  gating_controls = [
    for rc_key in each.value.gating_controls :
    aws_route53recoverycontrolconfig_routing_control.this[rc_key].arn
  ]

  target_controls = [
    for rc_key in each.value.target_controls :
    aws_route53recoverycontrolconfig_routing_control.this[rc_key].arn
  ]

  rule_config {
    inverted  = each.value.gating_rule.inverted
    threshold = each.value.gating_rule.threshold
    type      = each.value.gating_rule.type
  }
}

# ===========================================================================
# ROUTE 53 ROUTING CONTROL HEALTH CHECKS
# These health checks directly mirror the ON/OFF state of a routing control.
# Use them in Route 53 DNS failover records (ALIAS + health check).
# ===========================================================================
resource "aws_route53_health_check" "routing_control" {
  for_each = var.health_checks

  type                            = "RECOVERY_CONTROL"
  routing_control_arn             = aws_route53recoverycontrolconfig_routing_control.this[each.value.routing_control_key].arn
  disabled                        = each.value.disabled

  tags = merge(local.tags, {
    Name = coalesce(each.value.name, "${local.name}-${each.key}")
  })
}

# ===========================================================================
# RECOVERY GROUP (represents the full application)
# ===========================================================================
resource "aws_route53recoveryreadiness_recovery_group" "this" {
  count               = var.recovery_group != null ? 1 : 0
  recovery_group_name = var.recovery_group.name
  cells               = [for c in aws_route53recoveryreadiness_cell.this : c.arn]
  tags                = local.tags
}

resource "aws_route53recoveryreadiness_cell" "this" {
  for_each  = var.recovery_group != null ? { for c in var.recovery_group.cells : c.name => c } : {}
  cell_name = each.value.name
  cells     = each.value.zones
  tags      = local.tags
}

# ===========================================================================
# RESOURCE SETS (resources that need to be ready before failover)
# ===========================================================================
resource "aws_route53recoveryreadiness_resource_set" "this" {
  for_each          = var.readiness_checks
  resource_set_name = each.value.resource_set_name
  resource_set_type = each.value.resource_set_type

  dynamic "resources" {
    for_each = each.value.resources
    content {
      component_id = resources.value.component_id
      resource_arn = resources.value.resource_arn

      dynamic "dns_target_resource" {
        for_each = resources.value.dns_target_resource != null ? [resources.value.dns_target_resource] : []
        content {
          domain_name = dns_target_resource.value.domain_name

          dynamic "hosted_zone" {
            for_each = dns_target_resource.value.hosted_zone_arn != null ? [1] : []
            content {
              hosted_zone_arn = dns_target_resource.value.hosted_zone_arn
            }
          }

          target_resource {
            dynamic "r53_resource" {
              for_each = dns_target_resource.value.record_set_id != null ? [1] : []
              content {
                domain_name  = dns_target_resource.value.domain_name
                record_set_id = dns_target_resource.value.record_set_id
              }
            }
          }
        }
      }
    }
  }

  tags = local.tags
}

# ===========================================================================
# READINESS CHECKS (monitors resource set readiness score)
# ===========================================================================
resource "aws_route53recoveryreadiness_readiness_check" "this" {
  for_each           = var.readiness_checks
  readiness_check_name = "${local.name}-${each.key}"
  resource_set_name  = aws_route53recoveryreadiness_resource_set.this[each.key].resource_set_name
  tags               = local.tags
}
