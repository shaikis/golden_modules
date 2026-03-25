# =============================================================================
# tf-aws-route53 — Health Checks
#
# Three types:
#   1. endpoint     — HTTP/HTTPS/TCP checks against an IP or domain
#   2. cloudwatch   — alarm-based (for private resources, checks, etc.)
#   3. calculated   — AND/OR logic combining other health checks
#
# Health checks are referenced from records via health_check_key.
# =============================================================================

# ── Endpoint Health Checks ────────────────────────────────────────────────────

variable "health_checks" {
  description = <<-EOT
    Map of Route 53 health checks for endpoints (HTTP/HTTPS/TCP).
    Keys are referenced from records via health_check_key.

    Example — HTTPS health check:
      api_us_east = {
        type              = "HTTPS"
        fqdn              = "api.example.com"
        port              = 443
        resource_path     = "/health"
        request_interval  = 30
        failure_threshold = 3
      }

    Example — TCP health check on an IP:
      db_primary = {
        type       = "TCP"
        ip_address = "10.0.1.100"
        port       = 5432
      }
  EOT
  type = map(object({
    # Health check type: HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP
    type = string

    # Target: provide fqdn OR ip_address (not both for TCP)
    fqdn       = optional(string, null)
    ip_address = optional(string, null)
    port       = optional(number, 443)

    # HTTP/HTTPS specific
    resource_path = optional(string, "/")

    # String match: required for HTTP_STR_MATCH / HTTPS_STR_MATCH
    search_string = optional(string, null)

    # Check intervals
    # 10 = fast (billable at higher rate), 30 = standard (default)
    request_interval  = optional(number, 30)
    failure_threshold = optional(number, 3)

    # Enable HTTPS SNI (required for virtual-hosted HTTPS endpoints)
    enable_sni = optional(bool, true)

    # Check from ALL regions (recommended for production), or specific regions
    # Leave null for standard 3-region checking
    regions = optional(list(string), null)

    # CloudWatch alarm for latency / health percentage metrics
    measure_latency                 = optional(bool, false)
    cloudwatch_alarm_name           = optional(string, null)
    cloudwatch_alarm_region         = optional(string, null)
    insufficient_data_health_status = optional(string, "Healthy")

    # Invert health check (healthy = check fails, unhealthy = check passes)
    invert_healthcheck = optional(bool, false)

    # Tags
    name = optional(string, null) # Friendly name shown in Route 53 console
  }))
  default = {}
}

resource "aws_route53_health_check" "endpoint" {
  for_each = var.health_checks

  type               = each.value.type
  fqdn               = each.value.fqdn
  ip_address         = each.value.ip_address
  port               = each.value.port
  resource_path      = contains(["TCP"], each.value.type) ? null : each.value.resource_path
  search_string      = each.value.search_string
  request_interval   = each.value.request_interval
  failure_threshold  = each.value.failure_threshold
  enable_sni         = contains(["HTTPS", "HTTPS_STR_MATCH"], each.value.type) ? each.value.enable_sni : null
  regions            = each.value.regions
  measure_latency    = each.value.measure_latency
  invert_healthcheck = each.value.invert_healthcheck

  tags = merge(
    local.common_tags,
    { Name = each.value.name != null ? each.value.name : "${local.prefix}-${each.key}" }
  )
}

# ── Calculated Health Checks ──────────────────────────────────────────────────
# Combines multiple child health checks using AND/OR logic.
# Example: "healthy only if 2 out of 3 regional checks pass"

variable "calculated_health_checks" {
  description = <<-EOT
    Calculated health checks that combine child checks using AND/OR logic.
    Reference child checks by their key in var.health_checks.

    Example — healthy if at least 2 of 3 regions pass:
      api_global = {
        child_health_check_keys = ["api_us_east", "api_eu_west", "api_ap_southeast"]
        child_health_threshold  = 2
      }
  EOT
  type = map(object({
    # Keys of health checks from var.health_checks to combine
    child_health_check_keys = list(string)

    # Number of child checks that must be healthy for this check to be healthy
    # Equal to length(child_health_check_keys) = AND (all must pass)
    # Less than length = OR-like (N of M must pass)
    child_health_threshold = number

    invert_healthcheck = optional(bool, false)
    name               = optional(string, null)
  }))
  default = {}
}

resource "aws_route53_health_check" "calculated" {
  for_each = var.calculated_health_checks

  type                   = "CALCULATED"
  child_health_threshold = each.value.child_health_threshold
  child_healthchecks     = [for k in each.value.child_health_check_keys : aws_route53_health_check.endpoint[k].id]
  invert_healthcheck     = each.value.invert_healthcheck

  tags = merge(
    local.common_tags,
    { Name = each.value.name != null ? each.value.name : "${local.prefix}-${each.key}-calculated" }
  )
}

# ── CloudWatch Alarm Health Checks ────────────────────────────────────────────
# For monitoring private resources (EC2 inside VPC, internal load balancers)
# where standard HTTP checks cannot reach.

variable "cloudwatch_alarm_health_checks" {
  description = <<-EOT
    Health checks based on CloudWatch alarm state.
    Use for private resources that Route 53 cannot reach via the internet.

    The health check is considered healthy when the CloudWatch alarm is in OK state.

    Example:
      rds_primary = {
        alarm_name   = "prod-rds-primary-cpu"
        alarm_region = "us-east-1"
        insufficient_data_health_status = "Unhealthy"
      }
  EOT
  type = map(object({
    alarm_name                      = string
    alarm_region                    = string
    insufficient_data_health_status = optional(string, "Unhealthy")
    invert_healthcheck              = optional(bool, false)
    name                            = optional(string, null)
  }))
  default = {}
}

resource "aws_route53_health_check" "cloudwatch_alarm" {
  for_each = var.cloudwatch_alarm_health_checks

  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = each.value.alarm_name
  cloudwatch_alarm_region         = each.value.alarm_region
  insufficient_data_health_status = each.value.insufficient_data_health_status
  invert_healthcheck              = each.value.invert_healthcheck

  tags = merge(
    local.common_tags,
    { Name = each.value.name != null ? each.value.name : "${local.prefix}-${each.key}-cw" }
  )
}
