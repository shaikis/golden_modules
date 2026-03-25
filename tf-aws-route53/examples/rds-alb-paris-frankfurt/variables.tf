# =============================================================================
# Variables — Multi-ALB + Multi-RDS Paris/Frankfurt failover
#
# Scaled design: add an entry to the albs or rds_databases map to onboard
# a new service. No Terraform code changes needed — only tfvars.
#
# Each map entry has a primary and secondary nested block, making it clear
# which endpoint lives in Paris and which lives in Frankfurt.
# =============================================================================

# ── Naming ────────────────────────────────────────────────────────────────────

variable "name_prefix" {
  description = "Resource name prefix (e.g. 'prod')."
  type        = string
  default     = "prod"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

# ── Hosted Zones ──────────────────────────────────────────────────────────────

variable "public_zone_name" {
  description = "Public hosted zone domain (e.g. 'example.com'). All ALB records live here."
  type        = string
}

variable "private_zone_name" {
  description = "Private hosted zone domain (e.g. 'internal.example.com'). All RDS CNAMEs live here."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID associated with the private hosted zone."
  type        = string
}

# ── ALB Map ───────────────────────────────────────────────────────────────────
# One entry per ALB pair. Each entry has a primary (Paris) and secondary
# (Frankfurt) block. for_each expands this into all health checks and records.
#
# Route 53 creates per entry:
#   <dns_prefix>.<public_zone_name> → weighted A (primary,   weight=100 or 0)
#   <dns_prefix>.<public_zone_name> → weighted A (secondary, weight=0 or 100)
#
# planned_switchover (per-service):
#   false = primary (Paris) active   (weight=100), secondary standby (weight=0)
#   true  = secondary (Frankfurt) active (weight=100), primary offline (weight=0)
#
# Example entry in tfvars:
#   albs = {
#     api = {
#       dns_prefix         = "api"
#       planned_switchover = false
#       primary = {
#         dns_name    = "prod-api-paris-xxx.eu-west-3.elb.amazonaws.com"
#         zone_id     = "Z3Q77PNBQS71R4"
#         health_fqdn = "prod-api-paris-xxx.eu-west-3.elb.amazonaws.com"
#       }
#       secondary = {
#         dns_name    = "prod-api-frankfurt-yyy.eu-central-1.elb.amazonaws.com"
#         zone_id     = "Z215JYRZR1TBD5"
#         health_fqdn = "prod-api-frankfurt-yyy.eu-central-1.elb.amazonaws.com"
#       }
#     }
#   }

variable "albs" {
  description = <<-EOT
    Map of ALB pairs (primary = Paris, secondary = Frankfurt).
    Key = logical service name used in resource names and DNS.

    primary / secondary blocks contain:
      dns_name    — ALB DNS name   (from aws_lb.dns_name)
      zone_id     — ALB zone ID    (from aws_lb.zone_id)
      health_fqdn — FQDN Route 53 health check polls

    planned_switchover:
      false = primary active   (weight=100), secondary standby (weight=0)
      true  = secondary active (weight=100), primary offline   (weight=0)
  EOT
  type = map(object({
    # Subdomain: <dns_prefix>.<public_zone_name>
    dns_prefix = string

    # Primary ALB — Paris (eu-west-3)
    primary = object({
      dns_name    = string
      zone_id     = string
      health_fqdn = string
    })

    # Secondary ALB — Frankfurt (eu-central-1)
    secondary = object({
      dns_name    = string
      zone_id     = string
      health_fqdn = string
    })

    # Health check settings (shared between primary and secondary)
    health_path = optional(string, "/health")
    health_port = optional(number, 443)

    # Per-service planned switchover flag
    planned_switchover = optional(bool, false)

    # Set true if replacing an existing simple A record (atomic overwrite, no gap)
    allow_overwrite = optional(bool, true)
  }))
  default = {}
}

# ── RDS Database Map ──────────────────────────────────────────────────────────
# One entry per RDS instance pair (Paris primary + Frankfurt replica).
# for_each expands this into CloudWatch alarms + Route 53 CNAME failover records.
#
# Route 53 creates per entry in the private zone:
#   <dns_prefix>.<private_zone_name> → CNAME PRIMARY   (Paris endpoint)
#   <dns_prefix>.<private_zone_name> → CNAME SECONDARY (Frankfurt endpoint)
#
# Health checks use CloudWatch alarm state — Route 53 cannot TCP-check private
# RDS endpoints inside a VPC.
#
# Example entry in tfvars:
#   rds_databases = {
#     oracle_main = {
#       dns_prefix = "oracle-main"
#       primary = {
#         endpoint   = "prod-oracle-main.xxxx.eu-west-3.rds.amazonaws.com"
#         alarm_name = "prod-oracle-main-paris-health"
#       }
#       secondary = {
#         endpoint   = "prod-oracle-main-replica.yyyy.eu-central-1.rds.amazonaws.com"
#         alarm_name = "prod-oracle-main-frankfurt-health"
#       }
#     }
#   }

variable "rds_databases" {
  description = <<-EOT
    Map of RDS pairs (primary = Paris, secondary = Frankfurt).
    Key = logical database name used in resource names and DNS.

    primary / secondary blocks contain:
      endpoint   — RDS endpoint FQDN
      alarm_name — CloudWatch alarm name in the same region as the RDS instance

    CloudWatch alarm setup (one per RDS instance, in its own region):
      Metric:             DatabaseConnections
      Operator:           LessThanOrEqualToThreshold
      Threshold:          0
      treat_missing_data: breaching
      → Alarm OK    when RDS is UP  (connections exist or data present)
      → Alarm ALARM when RDS is DOWN (no connections or missing metric data)
  EOT
  type = map(object({
    # Subdomain: <dns_prefix>.<private_zone_name>
    dns_prefix = string

    # Primary RDS — Paris (eu-west-3)
    primary = object({
      endpoint   = string # RDS endpoint FQDN
      alarm_name = string # CloudWatch alarm name in eu-west-3
    })

    # Secondary RDS — Frankfurt (eu-central-1)
    secondary = object({
      endpoint   = string # RDS endpoint FQDN
      alarm_name = string # CloudWatch alarm name in eu-central-1
    })

    # DNS TTL for the CNAME records (low = faster failover resolution)
    ttl = optional(number, 60)

    # Set true if replacing an existing CNAME record (atomic overwrite)
    allow_overwrite = optional(bool, true)
  }))
  default = {}
}

# ── Global Switchover Override ────────────────────────────────────────────────

variable "global_planned_switchover" {
  description = <<-EOT
    Global override: set true to switch ALL ALBs to Frankfurt simultaneously.
    Useful for a full-region maintenance window on Paris.
    Per-service planned_switchover flags are OR-ed with this global flag.

    Use case: Paris region has an issue or full maintenance — shift everything at once.
      global_planned_switchover = true  → ALL ALBs go to Frankfurt
      global_planned_switchover = false → each ALB follows its own planned_switchover flag
  EOT
  type        = bool
  default     = false
}
