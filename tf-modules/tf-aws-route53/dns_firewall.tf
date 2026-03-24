# =============================================================================
# tf-aws-route53 — Route 53 Resolver DNS Firewall
#
# Inspects all outbound DNS queries from your VPC.
# Blocks or allows queries based on domain lists.
#
# Common use cases:
#   - Block known malware/C2 command-and-control domains (GuardDuty threat intel)
#   - Block crypto-mining pool domains
#   - Allow-list: only permit queries to known-good domains (strict mode)
#   - Block data exfiltration via DNS tunneling
#
# Architecture:
#   VPC → Route 53 Resolver → DNS Firewall rule group → BLOCK/ALLOW/ALERT
#
# AWS Managed Domain Lists (free):
#   AWSManagedDomainsMalwareDomainList
#   AWSManagedDomainsAggregateThreatList
#   AWSManagedDomainsBotnetCommandandControl
#
# To enable: set dns_firewall_rule_groups and dns_firewall_associations
# =============================================================================

variable "dns_firewall_domain_lists" {
  description = <<-EOT
    Map of custom DNS Firewall domain lists.
    Each list contains domains to block or allow (one domain per entry).

    Example — block crypto-mining pools:
      crypto_mining_domains = {
        domains = [
          "pool.minexmr.com",
          "xmr.pool.minergate.com",
          "*.nicehash.com"
        ]
      }
  EOT
  type = map(object({
    domains = list(string)
    name    = optional(string, null)
  }))
  default = {}
}

resource "aws_route53_resolver_firewall_domain_list" "this" {
  for_each = var.dns_firewall_domain_lists

  name    = each.value.name != null ? each.value.name : "${local.prefix}-${each.key}"
  domains = each.value.domains

  tags = local.common_tags
}

# ── DNS Firewall Rule Groups ───────────────────────────────────────────────────

variable "dns_firewall_rule_groups" {
  description = <<-EOT
    Map of DNS Firewall rule groups.
    Each rule group contains ordered rules that match domain lists.

    Actions: BLOCK (with response NXDOMAIN/NODATA/OVERRIDE), ALLOW, ALERT

    Example — block malware domains:
      security_rules = {
        rules = {
          block_malware = {
            priority        = 100
            domain_list_key = "crypto_mining_domains"   # from dns_firewall_domain_lists
            action          = "BLOCK"
            block_response  = "NXDOMAIN"
          }
          allow_trusted = {
            priority        = 200
            domain_list_key = "trusted_domains"
            action          = "ALLOW"
          }
        }
      }
  EOT
  type = map(object({
    rules = map(object({
      priority = number
      action   = string # "BLOCK", "ALLOW", "ALERT"

      # Reference a domain list by key from dns_firewall_domain_lists
      # OR provide a direct domain list ID
      domain_list_key = optional(string, null)
      domain_list_id  = optional(string, null)

      # For BLOCK action:
      block_response          = optional(string, "NXDOMAIN") # "NXDOMAIN", "NODATA", "OVERRIDE"
      block_override_domain   = optional(string, null)       # For OVERRIDE: redirect to this domain
      block_override_ttl      = optional(number, 300)
      block_override_dns_type = optional(string, "CNAME")
    }))
  }))
  default = {}
}

resource "aws_route53_resolver_firewall_rule_group" "this" {
  for_each = var.dns_firewall_rule_groups

  name = "${local.prefix}-${each.key}-fw-group"
  tags = local.common_tags
}

locals {
  # Flatten rules from all rule groups
  dns_firewall_rules_flat = merge([
    for group_key, group in var.dns_firewall_rule_groups : {
      for rule_key, rule in group.rules :
      "${group_key}-${rule_key}" => merge(rule, {
        group_key = group_key
        # Resolve domain list ID
        resolved_domain_list_id = rule.domain_list_id != null ? rule.domain_list_id : (
          rule.domain_list_key != null ? aws_route53_resolver_firewall_domain_list.this[rule.domain_list_key].id : null
        )
      })
    }
  ]...)
}

resource "aws_route53_resolver_firewall_rule" "this" {
  for_each = local.dns_firewall_rules_flat

  name                    = "${local.prefix}-${each.key}"
  action                  = each.value.action
  firewall_domain_list_id = each.value.resolved_domain_list_id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[each.value.group_key].id
  priority                = each.value.priority

  block_response          = each.value.action == "BLOCK" ? each.value.block_response : null
  block_override_domain   = each.value.action == "BLOCK" && each.value.block_response == "OVERRIDE" ? each.value.block_override_domain : null
  block_override_ttl      = each.value.action == "BLOCK" && each.value.block_response == "OVERRIDE" ? each.value.block_override_ttl : null
  block_override_dns_type = each.value.action == "BLOCK" && each.value.block_response == "OVERRIDE" ? each.value.block_override_dns_type : null
}

# ── DNS Firewall VPC Associations ─────────────────────────────────────────────

variable "dns_firewall_associations" {
  description = <<-EOT
    Associate DNS Firewall rule groups with VPCs.

    Example:
      security_rules_prod_vpc = {
        rule_group_key = "security_rules"
        vpc_id         = "vpc-0abc123"
        priority       = 100
        mutation_protection = "ENABLED"
      }
  EOT
  type = map(object({
    rule_group_key = string
    vpc_id         = string
    priority       = number

    # "ENABLED" = prevent disassociation without explicit override (production safety)
    # "DISABLED" = allow disassociation (default, easier to manage)
    mutation_protection = optional(string, "DISABLED")
  }))
  default = {}
}

resource "aws_route53_resolver_firewall_rule_group_association" "this" {
  for_each = var.dns_firewall_associations

  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.this[each.value.rule_group_key].id
  vpc_id                 = each.value.vpc_id
  priority               = each.value.priority
  mutation_protection    = each.value.mutation_protection
  name                   = "${local.prefix}-${each.key}"

  tags = local.common_tags
}
