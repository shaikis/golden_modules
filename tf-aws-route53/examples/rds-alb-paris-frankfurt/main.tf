# =============================================================================
# Scenario: Multi-ALB + Multi-RDS Paris ↔ Frankfurt failover
#
# Infrastructure:
#   Paris (eu-west-3)       : N ALBs [PRIMARY]  + N RDS instances [PRIMARY]
#   Frankfurt (eu-central-1): N ALBs [SECONDARY] + N RDS replicas  [SECONDARY]
#
# DNS names (NEVER change — applications always connect to these):
#   <dns_prefix>.<public_zone_name>   → ALB  (public zone,  weighted alias)
#   <dns_prefix>.<private_zone_name>  → RDS  (private zone, failover CNAME)
#
# ─── SCALING ─────────────────────────────────────────────────────────────────
# Adding a new ALB pair or RDS pair requires ONLY a new entry in tfvars.
# No Terraform code changes are needed — for_each handles everything.
#
# ─── HOW ALB FAILOVER WORKS ──────────────────────────────────────────────────
# AUTOMATIC (health-check driven):
#   Route 53 polls <primary.health_fqdn>/health every 30s from ~8 global points.
#   After 3 consecutive failures → health check = Unhealthy.
#   Route 53 stops returning the primary alias → secondary becomes active.
#   DNS TTL = 60s → clients re-resolve within 60s → now hitting Frankfurt ALB.
#   Total failover time: ~3 min (3×30s checks + 60s TTL).
#
# PLANNED SWITCHOVER (per-service):
#   Set planned_switchover = true on the relevant albs entry in tfvars.
#   Terraform sets primary weight=0, secondary weight=100.
#   Traffic drains from Paris gracefully. DNS name is unchanged.
#   Revert by setting planned_switchover = false and re-applying.
#
# GLOBAL MAINTENANCE (all services at once):
#   Set global_planned_switchover = true in tfvars.
#   All ALBs shift to Frankfurt simultaneously.
#
# ─── HOW RDS FAILOVER WORKS ──────────────────────────────────────────────────
# Route 53 cannot TCP-check private RDS endpoints inside a VPC.
# Instead, a CloudWatch alarm (DatabaseConnections ≤ 0) acts as the health
# signal. Route 53 polls the alarm state:
#   Alarm OK    → Healthy   → PRIMARY CNAME returned
#   Alarm ALARM → Unhealthy → Route 53 switches to SECONDARY CNAME
#
# To trigger planned RDS failover:
#   aws cloudwatch set-alarm-state \
#     --alarm-name <primary.alarm_name> \
#     --state-value ALARM \
#     --state-reason "Planned maintenance" \
#     --region eu-west-3
#
# ─── MIGRATION WITHOUT DISTURBING EXISTING RECORDS ────────────────────────────
# allow_overwrite = true (default on every entry) atomically replaces any
# existing simple A / CNAME record with the new weighted / failover records.
# The DNS name is identical — zero disruption to clients.
# =============================================================================

# ── CloudWatch alarms for RDS health ─────────────────────────────────────────
# One alarm per RDS instance, in the same region as the instance.
# Route 53 polls this alarm state instead of TCP-checking the private endpoint.
#
#   DatabaseConnections ≤ 0 with treat_missing_data = "breaching"
#   → OK    when RDS is UP   (connections present)
#   → ALARM when RDS is DOWN (zero connections or no metric data at all)

resource "aws_cloudwatch_metric_alarm" "rds_primary" {
  for_each = var.rds_databases
  provider = aws.paris

  alarm_name        = each.value.primary.alarm_name
  alarm_description = "Route53 health signal for RDS ${each.key} Paris (primary). ALARM triggers failover to Frankfurt."

  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  # CRITICAL: treat_missing_data = "breaching" fires the alarm when the RDS
  # instance is stopped, crashed, or being replaced (no metrics emitted).
  treat_missing_data = "breaching"

  dimensions = {
    # Extract the DB instance identifier from the endpoint FQDN:
    #   "prod-oracle.xxxx.eu-west-3.rds.amazonaws.com" → "prod-oracle"
    DBInstanceIdentifier = split(".", each.value.primary.endpoint)[0]
  }

  tags = merge(var.tags, {
    Service   = each.key
    Region    = "eu-west-3"
    Role      = "primary"
    ManagedBy = "terraform"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_secondary" {
  for_each = var.rds_databases
  provider = aws.frankfurt

  alarm_name        = each.value.secondary.alarm_name
  alarm_description = "Route53 health signal for RDS ${each.key} Frankfurt (secondary). ALARM marks replica unhealthy."

  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = split(".", each.value.secondary.endpoint)[0]
  }

  tags = merge(var.tags, {
    Service   = each.key
    Region    = "eu-central-1"
    Role      = "secondary"
    ManagedBy = "terraform"
  })
}

# ── Route 53 module ───────────────────────────────────────────────────────────
# health_checks and records are built entirely from the input maps.
# No code change is needed when adding or removing ALBs / RDS databases.

module "route53" {
  source = "../../"

  name        = "paris-frankfurt-failover"
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags

  # ── Hosted Zones ─────────────────────────────────────────────────────────────
  zones = {
    public = {
      name    = var.public_zone_name
      comment = "Public zone — ALB weighted failover Paris/Frankfurt"
    }
    private = {
      name         = var.private_zone_name
      comment      = "Private zone — RDS CNAME failover Paris/Frankfurt"
      private_zone = true
      vpc_ids      = [var.vpc_id]
    }
  }

  # ── ALB Health Checks ─────────────────────────────────────────────────────
  # Build: { "<key>_primary" = {...}, "<key>_secondary" = {...} } for every ALB.
  # Route 53 polls each FQDN from ~8 global checkpoints every 30 seconds.
  health_checks = merge(
    # Primary (Paris) health checks — one per ALB entry
    {
      for key, alb in var.albs :
      "${key}_primary" => {
        type              = "HTTPS"
        fqdn              = alb.primary.health_fqdn
        port              = alb.health_port
        resource_path     = alb.health_path
        request_interval  = 30
        failure_threshold = 3
        enable_sni        = true
        measure_latency   = true
        name              = "${key}-primary-paris"
      }
    },
    # Secondary (Frankfurt) health checks — one per ALB entry
    {
      for key, alb in var.albs :
      "${key}_secondary" => {
        type              = "HTTPS"
        fqdn              = alb.secondary.health_fqdn
        port              = alb.health_port
        resource_path     = alb.health_path
        request_interval  = 30
        failure_threshold = 3
        enable_sni        = true
        measure_latency   = true
        name              = "${key}-secondary-frankfurt"
      }
    }
  )

  # ── RDS CloudWatch Alarm Health Checks ───────────────────────────────────
  # Build: { "<key>_primary" = {...}, "<key>_secondary" = {...} } per RDS pair.
  # Route 53 reads the alarm state — no direct TCP connectivity needed.
  cloudwatch_alarm_health_checks = merge(
    # Primary (Paris) alarm health checks
    {
      for key, db in var.rds_databases :
      "${key}_primary" => {
        alarm_name                      = db.primary.alarm_name
        alarm_region                    = "eu-west-3"
        insufficient_data_health_status = "Unhealthy"
        name                            = "${key}-primary-paris"
      }
    },
    # Secondary (Frankfurt) alarm health checks
    {
      for key, db in var.rds_databases :
      "${key}_secondary" => {
        alarm_name                      = db.secondary.alarm_name
        alarm_region                    = "eu-central-1"
        insufficient_data_health_status = "Unhealthy"
        name                            = "${key}-secondary-frankfurt"
      }
    }
  )

  # ── DNS Records ───────────────────────────────────────────────────────────
  # Build all ALB weighted records + all RDS failover CNAME records in one map.
  # merge() flattens them into the single map the module expects.
  records = merge(

    # ── ALB PRIMARY records (Paris) ─────────────────────────────────────────
    # weight = 100 normally; weight = 0 when planned_switchover is active.
    # Health check guards: even at weight=100, an unhealthy Paris ALB will
    # not receive traffic — Route 53 automatically falls back to Frankfurt.
    {
      for key, alb in var.albs :
      "${key}_alb_primary" => {
        zone_key       = "public"
        name           = "${alb.dns_prefix}.${var.public_zone_name}"
        type           = "A"
        set_identifier = "${key}-paris-primary"

        # OR: per-service flag OR global override both shift weight to 0
        weight = (alb.planned_switchover || var.global_planned_switchover) ? 0 : 100

        health_check_key = "${key}_primary"

        alias_target = {
          name                   = alb.primary.dns_name
          zone_id                = alb.primary.zone_id
          evaluate_target_health = true
        }

        allow_overwrite = alb.allow_overwrite
      }
    },

    # ── ALB SECONDARY records (Frankfurt) ───────────────────────────────────
    # weight = 0 normally (standby); weight = 100 during planned switchover.
    {
      for key, alb in var.albs :
      "${key}_alb_secondary" => {
        zone_key       = "public"
        name           = "${alb.dns_prefix}.${var.public_zone_name}"
        type           = "A"
        set_identifier = "${key}-frankfurt-secondary"

        weight = (alb.planned_switchover || var.global_planned_switchover) ? 100 : 0

        health_check_key = "${key}_secondary"

        alias_target = {
          name                   = alb.secondary.dns_name
          zone_id                = alb.secondary.zone_id
          evaluate_target_health = true
        }

        allow_overwrite = alb.allow_overwrite
      }
    },

    # ── RDS PRIMARY CNAME records (Paris) ────────────────────────────────────
    # Failover routing: PRIMARY is always preferred when its health check is OK.
    # CloudWatch alarm health check makes Route 53 skip this record when Paris
    # RDS is down, falling back to the SECONDARY record below.
    {
      for key, db in var.rds_databases :
      "${key}_rds_primary" => {
        zone_key         = "private"
        name             = "${db.dns_prefix}.${var.private_zone_name}"
        type             = "CNAME"
        ttl              = db.ttl
        records          = [db.primary.endpoint]
        set_identifier   = "${key}-paris-primary"
        failover_role    = "PRIMARY"
        health_check_key = "${key}_primary"
        allow_overwrite  = db.allow_overwrite
      }
    },

    # ── RDS SECONDARY CNAME records (Frankfurt) ──────────────────────────────
    # Returned ONLY when the primary health check is Unhealthy.
    # Applications always connect to <dns_prefix>.<private_zone_name> —
    # the CNAME target silently changes during failover; no app config change.
    {
      for key, db in var.rds_databases :
      "${key}_rds_secondary" => {
        zone_key         = "private"
        name             = "${db.dns_prefix}.${var.private_zone_name}"
        type             = "CNAME"
        ttl              = db.ttl
        records          = [db.secondary.endpoint]
        set_identifier   = "${key}-frankfurt-secondary"
        failover_role    = "SECONDARY"
        health_check_key = "${key}_secondary"
        allow_overwrite  = db.allow_overwrite
      }
    }
  )
}
