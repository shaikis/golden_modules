# =============================================================================
# tf-aws-route53 — DNS Records (All Types + All Routing Policies)
#
# Routing policies supported per record:
#   simple        → standard DNS record (default)
#   weighted      → traffic split by weight (A/B testing, canary deploys)
#   latency       → serve from nearest AWS region
#   failover      → primary/secondary active-passive failover
#   geolocation   → route by country/continent/subdivision
#   geoproximity  → route by geographic proximity with bias
#   multivalue    → return multiple healthy IPs (client-side load balancing)
#   ip_based      → route by client CIDR range (IP-based routing)
#
# Record types supported: A, AAAA, CNAME, MX, TXT, NS, SOA, PTR, SRV, CAA, DS, NAPTR
# Alias targets: ALB, NLB, CloudFront, S3, API Gateway, Global Accelerator, VPC endpoint
# =============================================================================

variable "records" {
  description = <<-EOT
    Map of DNS records to create across all zones.
    Key = logical name (used in resource names, must be unique).

    Each record specifies which zone it belongs to via zone_key (matches a key
    in var.zones) OR zone_id (direct hosted zone ID).

    Routing policy is determined by which optional fields are set:
      - No routing fields    → simple routing
      - set_identifier +
        weight               → weighted routing
      - set_identifier +
        latency_region       → latency-based routing
      - set_identifier +
        failover_role        → failover routing (PRIMARY or SECONDARY)
      - set_identifier +
        geolocation          → geolocation routing
      - set_identifier +
        geoproximity         → geoproximity routing
      - set_identifier +
        multivalue_answer    → multivalue answer routing
      - set_identifier +
        cidr_collection_id   → IP-based routing

    Alias records: set alias_target instead of records + ttl.
  EOT
  type = map(object({
    # ── Required: which zone ──────────────────────────────────────────────────
    # Use zone_key (logical key from var.zones) OR zone_id (direct zone ID)
    zone_key = optional(string, null)
    zone_id  = optional(string, null)

    # ── Required: record identity ─────────────────────────────────────────────
    name = string # DNS name (relative to zone apex, or FQDN with trailing dot)
    type = string # A, AAAA, CNAME, MX, TXT, NS, SOA, PTR, SRV, CAA, DS, NAPTR

    # ── Standard records ──────────────────────────────────────────────────────
    ttl     = optional(number, 300)        # Required for non-alias records
    records = optional(list(string), null) # Record values; null for alias records

    # ── Alias records ─────────────────────────────────────────────────────────
    # Use instead of ttl + records for ALB, CloudFront, S3, API Gateway, etc.
    alias_target = optional(object({
      name                   = string # DNS name of the alias target
      zone_id                = string # Hosted zone ID of the alias target
      evaluate_target_health = optional(bool, true)
    }), null)

    # ── Routing policy fields (all optional) ──────────────────────────────────
    # Required for all non-simple routing policies
    set_identifier = optional(string, null) # Must be unique within name+type

    # Weighted routing: 0-255 (0 = no traffic, 255 = all traffic proportionally)
    weight = optional(number, null)

    # Latency routing: AWS region identifier (e.g. "us-east-1")
    latency_region = optional(string, null)

    # Failover routing: "PRIMARY" or "SECONDARY"
    failover_role = optional(string, null)

    # Geolocation routing
    geolocation = optional(object({
      continent   = optional(string, null) # "AF","AN","AS","EU","OC","NA","SA"
      country     = optional(string, null) # ISO 3166-1 alpha-2, e.g. "US"
      subdivision = optional(string, null) # US state abbreviation, e.g. "CA"
    }), null)

    # Geoproximity routing (requires Traffic Flow — for static use only)
    geoproximity = optional(object({
      aws_region       = optional(string, null)
      local_zone_group = optional(string, null)
      bias             = optional(number, 0) # -99 to +99
      coordinates = optional(object({
        latitude  = string
        longitude = string
      }), null)
    }), null)

    # Multivalue answer routing: true = return up to 8 healthy records
    multivalue_answer = optional(bool, null)

    # IP-based routing
    cidr_collection_id = optional(string, null)
    cidr_location_name = optional(string, null)

    # Health check: attach to this record (required for failover routing)
    health_check_key = optional(string, null) # key from var.health_checks map
    health_check_id  = optional(string, null) # direct health check ID (BYO)

    # Allow overwrite of existing records (useful for imports)
    allow_overwrite = optional(bool, false)
  }))
  default = {}
}

# ── Resolve zone IDs for records ──────────────────────────────────────────────

locals {
  # For each record, resolve the zone ID from zone_key or direct zone_id
  record_zone_ids = {
    for k, r in var.records :
    k => (
      r.zone_id != null ? r.zone_id :
      r.zone_key != null ? lookup(local.zone_id_map, r.zone_key, null) :
      null
    )
  }

  # Resolve health check IDs from keys or direct IDs
  # Checks all three health check resource types: endpoint, calculated, cloudwatch_alarm
  record_health_check_ids = {
    for k, r in var.records :
    k => (
      r.health_check_id != null ? r.health_check_id :
      r.health_check_key != null ? try(
        aws_route53_health_check.endpoint[r.health_check_key].id,
        try(
          aws_route53_health_check.calculated[r.health_check_key].id,
          try(
            aws_route53_health_check.cloudwatch_alarm[r.health_check_key].id,
            null
          )
        )
      ) : null
    )
  }
}

# ── DNS Records ───────────────────────────────────────────────────────────────

resource "aws_route53_record" "this" {
  for_each = { for k, v in var.records : k => v if local.record_zone_ids[k] != null }

  zone_id         = local.record_zone_ids[each.key]
  name            = each.value.name
  type            = each.value.type
  ttl             = each.value.alias_target == null ? each.value.ttl : null
  records         = each.value.alias_target == null ? each.value.records : null
  set_identifier  = each.value.set_identifier
  health_check_id = local.record_health_check_ids[each.key]
  allow_overwrite = each.value.allow_overwrite

  # ── Alias target ────────────────────────────────────────────────────────────
  dynamic "alias" {
    for_each = each.value.alias_target != null ? [each.value.alias_target] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # ── Weighted routing ────────────────────────────────────────────────────────
  dynamic "weighted_routing_policy" {
    for_each = each.value.weight != null ? [each.value.weight] : []
    content {
      weight = weighted_routing_policy.value
    }
  }

  # ── Latency-based routing ────────────────────────────────────────────────────
  dynamic "latency_routing_policy" {
    for_each = each.value.latency_region != null ? [each.value.latency_region] : []
    content {
      region = latency_routing_policy.value
    }
  }

  # ── Failover routing ─────────────────────────────────────────────────────────
  dynamic "failover_routing_policy" {
    for_each = each.value.failover_role != null ? [each.value.failover_role] : []
    content {
      type = failover_routing_policy.value
    }
  }

  # ── Geolocation routing ──────────────────────────────────────────────────────
  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation != null ? [each.value.geolocation] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # ── Geoproximity routing ─────────────────────────────────────────────────────
  dynamic "geoproximity_routing_policy" {
    for_each = each.value.geoproximity != null ? [each.value.geoproximity] : []
    content {
      aws_region       = geoproximity_routing_policy.value.aws_region
      local_zone_group = geoproximity_routing_policy.value.local_zone_group
      bias             = geoproximity_routing_policy.value.bias

      dynamic "coordinates" {
        for_each = geoproximity_routing_policy.value.coordinates != null ? [geoproximity_routing_policy.value.coordinates] : []
        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }

  # ── Multivalue answer routing ─────────────────────────────────────────────────
  multivalue_answer_routing_policy = each.value.multivalue_answer == true ? true : null

  # ── IP-based routing ─────────────────────────────────────────────────────────
  dynamic "cidr_routing_policy" {
    for_each = each.value.cidr_collection_id != null ? [each.value] : []
    content {
      collection_id = cidr_routing_policy.value.cidr_collection_id
      location_name = cidr_routing_policy.value.cidr_location_name
    }
  }
}

# ── CIDR Collections (for IP-based routing) ───────────────────────────────────

variable "cidr_collections" {
  description = <<-EOT
    CIDR collections for IP-based routing policies.
    Key = logical name. Each collection contains named CIDR locations.

    Example:
      my_collection = {
        locations = {
          us_east = {
            cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
          }
          eu_west = {
            cidr_blocks = ["192.168.0.0/16"]
          }
        }
      }
  EOT
  type = map(object({
    locations = map(object({
      cidr_blocks = list(string)
    }))
  }))
  default = {}
}

resource "aws_route53_cidr_collection" "this" {
  for_each = var.cidr_collections
  name     = "${local.prefix}-${each.key}"
}

locals {
  cidr_locations_flat = merge([
    for coll_key, coll in var.cidr_collections : {
      for loc_key, loc in coll.locations :
      "${coll_key}-${loc_key}" => {
        collection_key = coll_key
        location_name  = loc_key
        cidr_blocks    = loc.cidr_blocks
      }
    }
  ]...)
}

resource "aws_route53_cidr_location" "this" {
  for_each = local.cidr_locations_flat

  cidr_collection_id = aws_route53_cidr_collection.this[each.value.collection_key].id
  name               = each.value.location_name
  cidr_blocks        = each.value.cidr_blocks
}
