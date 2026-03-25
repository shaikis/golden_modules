# =============================================================================
# Production — Multi-ALB + Multi-RDS Paris/Frankfurt failover
# =============================================================================
# Deploy:
#   terraform init
#   terraform apply -var-file=prod.tfvars
#
# Planned ALB switchover for a single service (e.g. 'api'):
#   Set planned_switchover = true on that albs entry, then:
#   terraform apply -var-file=prod.tfvars
#
# Planned maintenance for ALL services at once:
#   Set global_planned_switchover = true, then:
#   terraform apply -var-file=prod.tfvars
#
# Planned RDS failover (force Paris RDS alarm to ALARM):
#   aws cloudwatch set-alarm-state \
#     --alarm-name <primary.alarm_name> \
#     --state-value ALARM \
#     --state-reason "Planned maintenance" \
#     --region eu-west-3
# =============================================================================

# ── Naming ────────────────────────────────────────────────────────────────────
name_prefix = "prod"
environment = "prod"

tags = {
  Tier        = "production"
  Criticality = "high"
  Owner       = "platform-team"
}

# ── Hosted zones ──────────────────────────────────────────────────────────────
public_zone_name  = "example.com"
private_zone_name = "internal.example.com"
vpc_id            = "vpc-0abc1234def567890"

# ── Global switchover override ────────────────────────────────────────────────
# Set true ONLY during a full Paris region maintenance window.
# This shifts ALL ALBs to Frankfurt simultaneously.
global_planned_switchover = false

# ── ALB pairs ─────────────────────────────────────────────────────────────────
# Each entry: one Paris ALB (primary) + one Frankfurt ALB (secondary).
# Route 53 creates:
#   <dns_prefix>.example.com → weighted A (primary,   weight=100 or 0)
#   <dns_prefix>.example.com → weighted A (secondary, weight=0 or 100)
#
# Health check zone IDs (fixed per region — do not change):
#   eu-west-3    (Paris)     : Z3Q77PNBQS71R4
#   eu-central-1 (Frankfurt) : Z215JYRZR1TBD5
#
# Get ALB DNS names from:
#   aws elbv2 describe-load-balancers --region eu-west-3    --query 'LoadBalancers[*].[DNSName,CanonicalHostedZoneId]'
#   aws elbv2 describe-load-balancers --region eu-central-1 --query 'LoadBalancers[*].[DNSName,CanonicalHostedZoneId]'

albs = {
  # ── API Gateway ALB ─────────────────────────────────────────────────────────
  api = {
    dns_prefix         = "api"
    planned_switchover = false # true = shift api.example.com to Frankfurt
    primary = {
      dns_name    = "prod-api-paris-1234567890.eu-west-3.elb.amazonaws.com"
      zone_id     = "Z3Q77PNBQS71R4"
      health_fqdn = "prod-api-paris-1234567890.eu-west-3.elb.amazonaws.com"
    }
    secondary = {
      dns_name    = "prod-api-frankfurt-0987654321.eu-central-1.elb.amazonaws.com"
      zone_id     = "Z215JYRZR1TBD5"
      health_fqdn = "prod-api-frankfurt-0987654321.eu-central-1.elb.amazonaws.com"
    }
  }

  # ── Web Frontend ALB ────────────────────────────────────────────────────────
  web = {
    dns_prefix         = "www"
    planned_switchover = false
    primary = {
      dns_name    = "prod-web-paris-1111111111.eu-west-3.elb.amazonaws.com"
      zone_id     = "Z3Q77PNBQS71R4"
      health_fqdn = "prod-web-paris-1111111111.eu-west-3.elb.amazonaws.com"
    }
    secondary = {
      dns_name    = "prod-web-frankfurt-2222222222.eu-central-1.elb.amazonaws.com"
      zone_id     = "Z215JYRZR1TBD5"
      health_fqdn = "prod-web-frankfurt-2222222222.eu-central-1.elb.amazonaws.com"
    }
  }

  # ── Admin Panel ALB ─────────────────────────────────────────────────────────
  admin = {
    dns_prefix         = "admin"
    planned_switchover = false
    health_path        = "/healthz" # custom health endpoint for this service
    primary = {
      dns_name    = "prod-admin-paris-3333333333.eu-west-3.elb.amazonaws.com"
      zone_id     = "Z3Q77PNBQS71R4"
      health_fqdn = "prod-admin-paris-3333333333.eu-west-3.elb.amazonaws.com"
    }
    secondary = {
      dns_name    = "prod-admin-frankfurt-4444444444.eu-central-1.elb.amazonaws.com"
      zone_id     = "Z215JYRZR1TBD5"
      health_fqdn = "prod-admin-frankfurt-4444444444.eu-central-1.elb.amazonaws.com"
    }
  }

  # ── Payments Service ALB ────────────────────────────────────────────────────
  payments = {
    dns_prefix         = "payments"
    planned_switchover = false
    primary = {
      dns_name    = "prod-payments-paris-5555555555.eu-west-3.elb.amazonaws.com"
      zone_id     = "Z3Q77PNBQS71R4"
      health_fqdn = "prod-payments-paris-5555555555.eu-west-3.elb.amazonaws.com"
    }
    secondary = {
      dns_name    = "prod-payments-frankfurt-6666666666.eu-central-1.elb.amazonaws.com"
      zone_id     = "Z215JYRZR1TBD5"
      health_fqdn = "prod-payments-frankfurt-6666666666.eu-central-1.elb.amazonaws.com"
    }
  }

  # ── Notifications Service ALB ───────────────────────────────────────────────
  notifications = {
    dns_prefix         = "notifications"
    planned_switchover = false
    primary = {
      dns_name    = "prod-notify-paris-7777777777.eu-west-3.elb.amazonaws.com"
      zone_id     = "Z3Q77PNBQS71R4"
      health_fqdn = "prod-notify-paris-7777777777.eu-west-3.elb.amazonaws.com"
    }
    secondary = {
      dns_name    = "prod-notify-frankfurt-8888888888.eu-central-1.elb.amazonaws.com"
      zone_id     = "Z215JYRZR1TBD5"
      health_fqdn = "prod-notify-frankfurt-8888888888.eu-central-1.elb.amazonaws.com"
    }
  }
}

# ── RDS database pairs ────────────────────────────────────────────────────────
# Each entry: one Paris RDS (primary) + one Frankfurt replica (secondary).
# Route 53 creates in the private zone:
#   <dns_prefix>.internal.example.com → CNAME PRIMARY   (Paris endpoint)
#   <dns_prefix>.internal.example.com → CNAME SECONDARY (Frankfurt endpoint)
#
# Applications always connect to <dns_prefix>.internal.example.com.
# During failover the CNAME target switches silently. Zero app config change.
#
# CloudWatch alarms are created automatically by this module (for_each).
# Alarm uses DatabaseConnections ≤ 0 with treat_missing_data = "breaching".
#
# Get RDS endpoints from:
#   aws rds describe-db-instances --region eu-west-3    --query 'DBInstances[*].Endpoint.Address'
#   aws rds describe-db-instances --region eu-central-1 --query 'DBInstances[*].Endpoint.Address'

rds_databases = {
  # ── Oracle ERP (primary workload) ───────────────────────────────────────────
  oracle_erp = {
    dns_prefix = "oracle-erp"
    primary = {
      endpoint   = "prod-oracle-erp.cxyz1234abcd.eu-west-3.rds.amazonaws.com"
      alarm_name = "prod-oracle-erp-paris-health"
    }
    secondary = {
      endpoint   = "prod-oracle-erp-replica.cxyz5678efgh.eu-central-1.rds.amazonaws.com"
      alarm_name = "prod-oracle-erp-frankfurt-health"
    }
  }

  # ── Oracle Financials ────────────────────────────────────────────────────────
  oracle_fin = {
    dns_prefix = "oracle-fin"
    primary = {
      endpoint   = "prod-oracle-fin.aaaa1111bbbb.eu-west-3.rds.amazonaws.com"
      alarm_name = "prod-oracle-fin-paris-health"
    }
    secondary = {
      endpoint   = "prod-oracle-fin-replica.aaaa2222cccc.eu-central-1.rds.amazonaws.com"
      alarm_name = "prod-oracle-fin-frankfurt-health"
    }
  }

  # ── PostgreSQL Orders ────────────────────────────────────────────────────────
  pg_orders = {
    dns_prefix = "pg-orders"
    ttl        = 30 # lower TTL for faster failover resolution on this critical DB
    primary = {
      endpoint   = "prod-pg-orders.dddd3333eeee.eu-west-3.rds.amazonaws.com"
      alarm_name = "prod-pg-orders-paris-health"
    }
    secondary = {
      endpoint   = "prod-pg-orders-replica.dddd4444ffff.eu-central-1.rds.amazonaws.com"
      alarm_name = "prod-pg-orders-frankfurt-health"
    }
  }

  # ── PostgreSQL Users ─────────────────────────────────────────────────────────
  pg_users = {
    dns_prefix = "pg-users"
    primary = {
      endpoint   = "prod-pg-users.gggg5555hhhh.eu-west-3.rds.amazonaws.com"
      alarm_name = "prod-pg-users-paris-health"
    }
    secondary = {
      endpoint   = "prod-pg-users-replica.gggg6666iiii.eu-central-1.rds.amazonaws.com"
      alarm_name = "prod-pg-users-frankfurt-health"
    }
  }

  # ── MySQL Catalog ────────────────────────────────────────────────────────────
  mysql_catalog = {
    dns_prefix = "mysql-catalog"
    primary = {
      endpoint   = "prod-mysql-catalog.jjjj7777kkkk.eu-west-3.rds.amazonaws.com"
      alarm_name = "prod-mysql-catalog-paris-health"
    }
    secondary = {
      endpoint   = "prod-mysql-catalog-replica.jjjj8888llll.eu-central-1.rds.amazonaws.com"
      alarm_name = "prod-mysql-catalog-frankfurt-health"
    }
  }
}
