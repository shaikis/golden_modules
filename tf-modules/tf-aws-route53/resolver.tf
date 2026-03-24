# =============================================================================
# tf-aws-route53 — Route 53 Resolver
#
# Enables DNS resolution between AWS VPCs and on-premises networks.
#
# Components:
#   Inbound endpoints  — on-premises resolvers forward queries to AWS
#                        → queries for .internal.example.com resolve in Route 53
#   Outbound endpoints — AWS Lambda/EC2 forward queries to on-premises DNS
#                        → queries for .corp.example.com resolve on-premises
#   Resolver rules     — define which domains are forwarded where
#   Rule associations  — attach forwarding rules to VPCs
#
# Architecture:
#   On-premises → Inbound endpoint IPs → Route 53 Private Zone
#   AWS VPC     → Outbound endpoint    → On-premises DNS server
# =============================================================================

variable "resolver_endpoints" {
  description = <<-EOT
    Map of Route 53 Resolver endpoints (inbound or outbound).

    Inbound endpoint:  receives DNS queries from outside AWS (on-premises → AWS)
    Outbound endpoint: forwards DNS queries from AWS to external DNS servers

    Each endpoint requires at least 2 IP addresses in different AZs for high availability.

    Example — inbound endpoint for on-premises → AWS resolution:
      inbound_prod = {
        direction          = "INBOUND"
        security_group_ids = ["sg-0abc123"]
        ip_addresses = [
          { subnet_id = "subnet-0abc1", ip = "10.0.1.53" },
          { subnet_id = "subnet-0abc2", ip = "10.0.2.53" }
        ]
      }

    Example — outbound endpoint for AWS → on-premises resolution:
      outbound_prod = {
        direction          = "OUTBOUND"
        security_group_ids = ["sg-0def456"]
        ip_addresses = [
          { subnet_id = "subnet-0abc1" },
          { subnet_id = "subnet-0abc2" }
        ]
      }
  EOT
  type = map(object({
    # "INBOUND" or "OUTBOUND"
    direction = string

    # Security group IDs controlling traffic to/from the endpoint ENIs
    security_group_ids = list(string)

    # IP addresses (at least 2, in different AZs)
    ip_addresses = list(object({
      subnet_id = string
      ip        = optional(string, null) # Specific IP; null = auto-assign
    }))

    # Endpoint protocol: Do53 (plain DNS) or DoH (DNS over HTTPS)
    protocols = optional(list(string), ["Do53"])
  }))
  default = {}
}

resource "aws_route53_resolver_endpoint" "this" {
  for_each = var.resolver_endpoints

  name               = "${local.prefix}-${each.key}"
  direction          = each.value.direction
  security_group_ids = each.value.security_group_ids
  protocols          = each.value.protocols

  dynamic "ip_address" {
    for_each = each.value.ip_addresses
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = merge(local.common_tags, { Direction = each.value.direction })
}

# ── Resolver Forwarding Rules ─────────────────────────────────────────────────

variable "resolver_rules" {
  description = <<-EOT
    Map of Route 53 Resolver forwarding rules.
    Rules tell Route 53 to forward queries for specific domains to target DNS servers.

    Types:
      FORWARD   → forward to specified target IP(s), e.g. on-premises DNS
      SYSTEM    → override: let Route 53 handle this domain (default behavior)
      RECURSIVE → use Route 53 Resolver (for public domains)

    Example — forward .corp.example.com to on-premises DNS:
      corp_domain = {
        domain_name           = "corp.example.com"
        rule_type             = "FORWARD"
        resolver_endpoint_key = "outbound_prod"
        target_ips = [
          { ip = "192.168.1.53", port = 53 },
          { ip = "192.168.2.53", port = 53 }
        ]
        vpc_ids = ["vpc-0abc123"]
      }
  EOT
  type = map(object({
    domain_name = string

    # "FORWARD", "SYSTEM", or "RECURSIVE"
    rule_type = optional(string, "FORWARD")

    # Key from var.resolver_endpoints (must be an OUTBOUND endpoint)
    resolver_endpoint_key = optional(string, null)

    # Target DNS server IPs (required for FORWARD rules)
    target_ips = optional(list(object({
      ip   = string
      port = optional(number, 53)
    })), [])

    # VPCs to associate this rule with
    vpc_ids = optional(list(string), [])
  }))
  default = {}
}

resource "aws_route53_resolver_rule" "this" {
  for_each = var.resolver_rules

  domain_name          = each.value.domain_name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.resolver_endpoint_key != null ? aws_route53_resolver_endpoint.this[each.value.resolver_endpoint_key].id : null
  name                 = "${local.prefix}-${each.key}"

  dynamic "target_ip" {
    for_each = each.value.target_ips
    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = local.common_tags
}

# ── Rule → VPC Associations ───────────────────────────────────────────────────

locals {
  resolver_rule_vpc_associations = merge([
    for rule_key, rule in var.resolver_rules : {
      for idx, vpc_id in rule.vpc_ids :
      "${rule_key}-vpc${idx}" => {
        rule_key = rule_key
        vpc_id   = vpc_id
      }
    }
  ]...)
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each = local.resolver_rule_vpc_associations

  resolver_rule_id = aws_route53_resolver_rule.this[each.value.rule_key].id
  vpc_id           = each.value.vpc_id
}
