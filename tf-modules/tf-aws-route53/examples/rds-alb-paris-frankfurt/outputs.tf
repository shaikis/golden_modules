# =============================================================================
# Outputs — Multi-ALB + Multi-RDS Paris/Frankfurt failover
# =============================================================================

output "zone_ids" {
  description = "Hosted zone IDs (public + private)."
  value       = module.route53.zone_ids
}

output "zone_name_servers" {
  description = "Name servers for the public zone. Update your domain registrar with these."
  value       = module.route53.zone_name_servers
}

# ── Per-ALB DNS FQDNs ─────────────────────────────────────────────────────────

output "alb_fqdns" {
  description = <<-EOT
    DNS FQDNs for every ALB pair.
    Map key = logical service name from var.albs.
    These values NEVER change — applications always connect to these names
    regardless of which region (Paris or Frankfurt) is currently active.
  EOT
  value = {
    for key, alb in var.albs :
    key => "${alb.dns_prefix}.${var.public_zone_name}"
  }
}

# ── Per-RDS DNS FQDNs ─────────────────────────────────────────────────────────

output "rds_fqdns" {
  description = <<-EOT
    DNS FQDNs for every RDS failover pair.
    Map key = logical database name from var.rds_databases.
    These values NEVER change — applications always connect to these names.
    During failover the CNAME target switches silently; no app config change.
  EOT
  value = {
    for key, db in var.rds_databases :
    key => "${db.dns_prefix}.${var.private_zone_name}"
  }
}

# ── Health Check IDs ──────────────────────────────────────────────────────────

output "alb_health_check_ids" {
  description = "Route 53 HTTPS health check IDs for all ALB endpoints. Monitor these in the Route 53 Health Checks console."
  value       = module.route53.health_check_ids
}

output "rds_cloudwatch_health_check_ids" {
  description = "Route 53 CloudWatch alarm health check IDs for all RDS instances."
  value       = module.route53.cloudwatch_health_check_ids
}

# ── Per-service switchover status ─────────────────────────────────────────────

output "alb_switchover_status" {
  description = <<-EOT
    Current planned-switchover state per ALB service.
    ACTIVE   = Paris primary receiving all traffic (weight=100)
    STANDBY  = Frankfurt receiving traffic; Paris is in maintenance (weight=0)
    GLOBAL   = All services shifted to Frankfurt via global_planned_switchover
  EOT
  value = {
    for key, alb in var.albs :
    key => (
      var.global_planned_switchover ? "GLOBAL SWITCHOVER — Frankfurt active (all services)" :
      alb.planned_switchover ? "MAINTENANCE — Frankfurt active (weight=100), Paris offline (weight=0)" :
      "NORMAL — Paris active (weight=100), Frankfurt on standby (weight=0)"
    )
  }
}

output "rds_failover_mode" {
  description = "Failover mode for RDS is always AUTOMATIC (driven by CloudWatch alarm state)."
  value = {
    for key, db in var.rds_databases :
    key => "AUTOMATIC — Paris PRIMARY when alarm OK; Frankfurt SECONDARY when alarm ALARM"
  }
}

# ── Operational runbooks ──────────────────────────────────────────────────────

output "runbook_planned_alb_switchover" {
  description = "Steps for a planned ALB maintenance window (single service or all services)."
  value       = <<-EOT
    ── PLANNED ALB SWITCHOVER — single service ───────────────────────────────
    1. Edit prod.tfvars: in the albs map, set planned_switchover = true
       on the service(s) you want to move to Frankfurt.
    2. Run: terraform apply -var-file=prod.tfvars
       → Paris weight set to 0, Frankfurt weight set to 100 for that service.
       → Within 60 s (1 TTL cycle) all new requests go to Frankfurt ALB.
       → Existing connections drain naturally.
    3. Perform maintenance on Paris ALB / application.
    4. Edit prod.tfvars: set planned_switchover = false.
    5. Run: terraform apply -var-file=prod.tfvars → traffic returns to Paris.

    ── PLANNED ALB SWITCHOVER — all services at once ─────────────────────────
    1. Edit prod.tfvars: set global_planned_switchover = true
    2. Run: terraform apply -var-file=prod.tfvars
       → All ALBs shift to Frankfurt simultaneously.
    3. After maintenance: set global_planned_switchover = false, re-apply.

    DNS names NEVER change throughout. No application reconfiguration needed.
  EOT
}

output "runbook_planned_rds_switchover" {
  description = "Steps for a planned RDS maintenance window (works for any database in the map)."
  value       = <<-EOT
    ── PLANNED RDS SWITCHOVER (Paris → Frankfurt replica) ────────────────────
    Replace <SERVICE> with the rds_databases map key (e.g. oracle_main, pg_orders).
    Replace <ALARM_NAME> with the primary.alarm_name for that service.

    Option A — Force via CloudWatch alarm state (instant, no RDS stop needed):
      aws cloudwatch set-alarm-state \
        --alarm-name <ALARM_NAME> \
        --state-value ALARM \
        --state-reason "Planned maintenance window" \
        --region eu-west-3
      → Route 53 immediately serves Frankfurt CNAME for <dns_prefix>.<private_zone>
      → After maintenance:
      aws cloudwatch set-alarm-state \
        --alarm-name <ALARM_NAME> \
        --state-value OK \
        --state-reason "Maintenance complete" \
        --region eu-west-3

    Option B — Oracle/Postgres replica promotion (major version upgrade):
      1. Force alarm to ALARM (Option A above)
      2. aws rds promote-read-replica \
           --db-instance-identifier <frankfurt-replica-id> \
           --region eu-central-1
      3. Update secondary.endpoint in tfvars to the promoted standalone endpoint
      4. terraform apply -var-file=prod.tfvars
      5. Set up a new Paris RDS instance → becomes the new replica
      6. Revert alarm state when ready to fail back

    DNS name NEVER changes. Connection strings in application config: NO CHANGE.
  EOT
}

output "runbook_add_new_service" {
  description = "How to onboard a new ALB or RDS pair without any Terraform code changes."
  value       = <<-EOT
    ── ADDING A NEW ALB PAIR ─────────────────────────────────────────────────
    In prod.tfvars, add a new entry to the albs map:

      albs = {
        # ... existing entries ...
        payments = {
          dns_prefix         = "payments"
          planned_switchover = false
          primary = {
            dns_name    = "prod-payments-paris-xxx.eu-west-3.elb.amazonaws.com"
            zone_id     = "Z3Q77PNBQS71R4"
            health_fqdn = "prod-payments-paris-xxx.eu-west-3.elb.amazonaws.com"
          }
          secondary = {
            dns_name    = "prod-payments-frankfurt-yyy.eu-central-1.elb.amazonaws.com"
            zone_id     = "Z215JYRZR1TBD5"
            health_fqdn = "prod-payments-frankfurt-yyy.eu-central-1.elb.amazonaws.com"
          }
        }
      }

    Then: terraform apply -var-file=prod.tfvars
    → 2 health checks + 2 weighted A records created automatically.

    ── ADDING A NEW RDS PAIR ─────────────────────────────────────────────────
    In prod.tfvars, add a new entry to the rds_databases map:

      rds_databases = {
        # ... existing entries ...
        pg_orders = {
          dns_prefix = "pg-orders"
          primary = {
            endpoint   = "prod-pg-orders.xxxx.eu-west-3.rds.amazonaws.com"
            alarm_name = "prod-pg-orders-paris-health"
          }
          secondary = {
            endpoint   = "prod-pg-orders-replica.yyyy.eu-central-1.rds.amazonaws.com"
            alarm_name = "prod-pg-orders-frankfurt-health"
          }
        }
      }

    Then: terraform apply -var-file=prod.tfvars
    → 2 CloudWatch alarms + 2 alarm health checks + 2 failover CNAMEs created automatically.
    NO code changes needed in any .tf file.
  EOT
}
