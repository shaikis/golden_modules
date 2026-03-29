# =============================================================================
# SCENARIO: Real-Time Payment Platform — Multi-Region Active/Passive Failover
#
# Architecture:
#   PRIMARY:   us-east-1 — handles all live payment traffic
#   FAILOVER:  us-west-2 — warm standby, receives MSK replication + DynamoDB global table
#
# ARC Routing Controls:
#   primary-cell-on   = ON  → Route 53 sends traffic to us-east-1
#   failover-cell-on  = OFF → Route 53 does NOT send traffic to us-west-2
#
# FAILOVER SCENARIO (region down):
#   1. primary-cell-on  → set to OFF
#   2. failover-cell-on → set to ON
#   → Safety Rule ensures at least 1 cell is always ON (prevents blackout)
#   → Route 53 flips DNS within 60s (TTL + health check propagation)
#   → MSK Replicator has already synced topics to us-west-2
#   → DynamoDB global table is active in both regions
#
# SWITCHBACK SCENARIO (planned):
#   1. Set gating control "maintenance-mode" to ON
#   2. Drain us-east-1 (wait 5s safety rule wait_period_ms)
#   3. Turn primary-cell-on back ON, failover-cell-on OFF
#   4. Set maintenance-mode OFF
# =============================================================================

provider "aws" { region = "us-east-1" }

# Reuse existing Route 53 hosted zone
data "aws_route53_zone" "payments" {
  name = var.hosted_zone_name
}

module "arc" {
  source      = "../../"
  name        = "payments-arc"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  create_cluster = true

  # ── Control Panels ──────────────────────────────────────────────────────
  control_panels = {
    payments = {
      name = "${var.name}-payments-control-panel"
    }
    maintenance = {
      name = "${var.name}-maintenance-control-panel"
    }
  }

  # ── Routing Controls ────────────────────────────────────────────────────
  routing_controls = {
    primary-cell = {
      name              = "${var.name}-primary-us-east-1"
      control_panel_key = "payments"
    }
    failover-cell = {
      name              = "${var.name}-failover-us-west-2"
      control_panel_key = "payments"
    }
    maintenance-mode = {
      name              = "${var.name}-maintenance-gate"
      control_panel_key = "maintenance"
    }
  }

  # ── Safety Rules ────────────────────────────────────────────────────────
  safety_rules = {
    # CRITICAL: At least 1 payment cell must always be ON
    # Prevents both cells being switched OFF simultaneously (full blackout)
    min-one-cell-active = {
      name              = "${var.name}-min-one-cell-always-on"
      control_panel_key = "payments"
      type              = "ASSERTION"
      wait_period_ms    = 5000  # 5 second safety delay before applying

      asserted_controls = ["primary-cell", "failover-cell"]
      assertion_rule = {
        inverted  = false   # Assert controls are ON (not OFF)
        threshold = 1       # At LEAST 1 must be ON
        type      = "ATLEAST"
      }
    }

    # GATING: Maintenance mode must be ON before toggling primary cell
    # Prevents accidental primary failover outside of maintenance windows
    maintenance-gate-for-primary = {
      name              = "${var.name}-maintenance-gate-primary"
      control_panel_key = "maintenance"
      type              = "GATING"
      wait_period_ms    = 2000

      gating_controls = ["maintenance-mode"]
      target_controls  = ["primary-cell"]
      gating_rule = {
        inverted  = false
        threshold = 1
        type      = "ATLEAST"
      }
    }
  }

  # ── Route 53 Health Checks ───────────────────────────────────────────────
  health_checks = {
    primary-cell = {
      routing_control_key = "primary-cell"
      name                = "${var.name}-hc-primary-us-east-1"
      disabled            = false  # Primary starts enabled (ON)
    }
    failover-cell = {
      routing_control_key = "failover-cell"
      name                = "${var.name}-hc-failover-us-west-2"
      disabled            = true   # Failover starts disabled (OFF) — warm standby
    }
  }

  # ── Recovery Group (Readiness) ───────────────────────────────────────────
  recovery_group = {
    name = "${var.name}-payments-recovery-group"
    cells = [
      { name = "${var.name}-primary-cell-us-east-1",  zones = [] },
      { name = "${var.name}-failover-cell-us-west-2", zones = [] },
    ]
  }

  # ── Readiness Checks ─────────────────────────────────────────────────────
  readiness_checks = {
    # Monitor MSK cluster readiness in both regions
    msk-primary = {
      resource_set_name = "${var.name}-msk-primary"
      resource_set_type = "AWS::MSK::Cluster"
      resources = [
        {
          component_id = "primary"
          resource_arn = var.msk_primary_cluster_arn
        }
      ]
    }
    msk-failover = {
      resource_set_name = "${var.name}-msk-failover"
      resource_set_type = "AWS::MSK::Cluster"
      resources = [
        {
          component_id = "failover"
          resource_arn = var.msk_failover_cluster_arn
        }
      ]
    }
    # Monitor DynamoDB global table replication lag
    dynamodb-payments = {
      resource_set_name = "${var.name}-dynamodb-payments"
      resource_set_type = "AWS::DynamoDB::Table"
      resources = [
        { component_id = "primary",  resource_arn = var.dynamodb_payments_table_arn_primary },
        { component_id = "failover", resource_arn = var.dynamodb_payments_table_arn_failover },
      ]
    }
    # Monitor Lambda functions (ensure code is deployed in failover region)
    lambda-payment-initiator = {
      resource_set_name = "${var.name}-lambda-initiator"
      resource_set_type = "AWS::Lambda::Function"
      resources = [
        { component_id = "primary",  resource_arn = var.lambda_initiator_arn_primary },
        { component_id = "failover", resource_arn = var.lambda_initiator_arn_failover },
      ]
    }
  }
}

# ── Route 53 Failover DNS Records ────────────────────────────────────────────
resource "aws_route53_record" "api_primary" {
  zone_id = data.aws_route53_zone.payments.zone_id
  name    = var.api_subdomain
  type    = "A"

  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = module.arc.health_check_ids["primary-cell"]

  alias {
    name                   = var.cloudfront_domain_name_primary
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront hosted zone ID (constant)
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_failover" {
  zone_id = data.aws_route53_zone.payments.zone_id
  name    = var.api_subdomain
  type    = "A"

  set_identifier = "failover"
  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = module.arc.health_check_ids["failover-cell"]

  alias {
    name                   = var.cloudfront_domain_name_failover
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "arc_cluster_arn"         { value = module.arc.cluster_arn }
output "arc_cluster_endpoints"   { value = module.arc.cluster_endpoints }
output "routing_control_arns"    { value = module.arc.routing_control_arns }
output "safety_rule_arns"        { value = module.arc.safety_rule_arns }
output "health_check_ids"        { value = module.arc.health_check_ids }
output "recovery_group_arn"      { value = module.arc.recovery_group_arn }
output "readiness_check_arns"    { value = module.arc.readiness_check_arns }
output "api_dns_name"            { value = "${var.api_subdomain}.${var.hosted_zone_name}" }

output "failover_runbook" {
  description = "CLI commands for emergency failover to us-west-2."
  value = <<-RUNBOOK
    ===== EMERGENCY FAILOVER RUNBOOK =====
    Region: us-east-1 → us-west-2

    Step 1: Open maintenance gate (allows primary-cell routing control changes)
    aws route53-recovery-cluster update-routing-control-state \
      --routing-control-arn ${module.arc.routing_control_arns["maintenance-mode"]} \
      --routing-control-state ON \
      --endpoint-url <cluster-endpoint>

    Step 2: Disable primary cell (stops traffic to us-east-1)
    aws route53-recovery-cluster update-routing-control-state \
      --routing-control-arn ${module.arc.routing_control_arns["primary-cell"]} \
      --routing-control-state OFF \
      --endpoint-url <cluster-endpoint>

    Step 3: Enable failover cell (starts traffic to us-west-2)
    aws route53-recovery-cluster update-routing-control-state \
      --routing-control-arn ${module.arc.routing_control_arns["failover-cell"]} \
      --routing-control-state ON \
      --endpoint-url <cluster-endpoint>

    Step 4: Close maintenance gate
    aws route53-recovery-cluster update-routing-control-state \
      --routing-control-arn ${module.arc.routing_control_arns["maintenance-mode"]} \
      --routing-control-state OFF \
      --endpoint-url <cluster-endpoint>

    DNS failover propagates within ~60 seconds (Route 53 TTL).
    ===== END RUNBOOK =====
  RUNBOOK
}
