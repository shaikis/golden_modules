# =============================================================================
# tf-aws-route53 — Hosted Zones
#
# BYO Pattern per zone:
#   zone_id = null      → module creates the hosted zone
#   zone_id = "Z..."    → module uses existing zone (all records still created in it)
#
# Types:
#   Public zone:  comment = "...", private_zone = false (default)
#   Private zone: private_zone = true, vpc_ids = ["vpc-xxx"]
# =============================================================================

variable "zones" {
  description = <<-EOT
    Map of hosted zones to manage.
    Key = logical name used internally (does not affect AWS resource name).
    The actual DNS name is set in the `name` field.

    BYO pattern:
      zone_id = null    → module creates the zone
      zone_id = "Z..."  → module uses existing zone (records still created in it)

    Example — create a public zone:
      main = {
        name    = "example.com"
        comment = "Primary public hosted zone"
      }

    Example — BYO an existing zone:
      main = {
        name    = "example.com"
        zone_id = "Z1234567890ABC"
      }

    Example — private zone with VPC:
      internal = {
        name         = "internal.example.com"
        private_zone = true
        vpc_ids      = ["vpc-0abc123def456789"]
      }
  EOT
  type = map(object({
    # The DNS domain name for the hosted zone (e.g. "example.com")
    name = string

    # BYO: provide an existing zone ID to skip zone creation
    zone_id = optional(string, null)

    # Human-readable description shown in the Route 53 console
    comment = optional(string, "Managed by Terraform")

    # true = private zone (visible only within associated VPCs)
    private_zone = optional(bool, false)

    # List of VPC IDs to associate with a private hosted zone
    # First VPC in the list is the "primary" association (set at zone creation)
    # Additional VPCs are added via separate aws_route53_zone_association resources
    vpc_ids = optional(list(string), [])

    # Reusable delegation set ID (public zones only)
    # Ensures consistent name servers across environments
    delegation_set_id = optional(string, null)

    # Force destroy: allow Terraform to delete the zone even if it has records
    force_destroy = optional(bool, false)
  }))
  default = {}
}

# ── Create Hosted Zones ───────────────────────────────────────────────────────

resource "aws_route53_zone" "this" {
  for_each = { for k, v in var.zones : k => v if v.zone_id == null }

  name              = each.value.name
  comment           = each.value.comment
  delegation_set_id = each.value.private_zone ? null : each.value.delegation_set_id
  force_destroy     = each.value.force_destroy

  # Primary VPC for private zones (required at zone creation time)
  dynamic "vpc" {
    for_each = each.value.private_zone && length(each.value.vpc_ids) > 0 ? [each.value.vpc_ids[0]] : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(local.common_tags, { ZoneName = each.value.name })
}

# ── Additional VPC Associations (private zones) ───────────────────────────────
# The first VPC is handled at zone creation. Additional VPCs need separate resources.

locals {
  # Build a flat map of zone_key → vpc_id for all ADDITIONAL VPCs (index > 0)
  additional_vpc_associations = merge([
    for zone_key, zone in var.zones : {
      for idx, vpc_id in slice(zone.vpc_ids, 1, length(zone.vpc_ids)) :
      "${zone_key}-vpc${idx + 1}" => {
        zone_key = zone_key
        vpc_id   = vpc_id
      }
    }
    if zone.private_zone && zone.zone_id == null && length(zone.vpc_ids) > 1
  ]...)

  # Also handle BYO zones that need VPC associations
  byo_vpc_associations = merge([
    for zone_key, zone in var.zones : {
      for idx, vpc_id in zone.vpc_ids :
      "${zone_key}-byo-vpc${idx}" => {
        zone_key = zone_key
        zone_id  = zone.zone_id
        vpc_id   = vpc_id
      }
    }
    if zone.private_zone && zone.zone_id != null
  ]...)
}

resource "aws_route53_zone_association" "additional" {
  for_each = local.additional_vpc_associations

  zone_id = aws_route53_zone.this[each.value.zone_key].zone_id
  vpc_id  = each.value.vpc_id
}

resource "aws_route53_zone_association" "byo" {
  for_each = local.byo_vpc_associations

  zone_id = each.value.zone_id
  vpc_id  = each.value.vpc_id
}

# ── Reusable Delegation Sets ──────────────────────────────────────────────────
# Ensures the same name servers are used across multiple hosted zones.
# Useful when you want to pin NS records in a parent domain once.

variable "create_delegation_sets" {
  description = <<-EOT
    Map of reusable delegation sets to create.
    Key = logical name. Use the output delegation_set_name_servers to get the NS records.
    Reference in zones with delegation_set_id = module.route53.delegation_set_ids["key"].
  EOT
  type = map(object({
    reference_name = optional(string, null) # Optional caller reference for idempotency
  }))
  default = {}
}

resource "aws_route53_delegation_set" "this" {
  for_each = var.create_delegation_sets

  reference_name = each.value.reference_name
}
