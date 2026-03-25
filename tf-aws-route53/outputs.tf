# =============================================================================
# tf-aws-route53 — Outputs
# =============================================================================

# ── Hosted Zones ──────────────────────────────────────────────────────────────

output "zone_ids" {
  description = "Map of zone key → hosted zone ID (created by module)."
  value       = { for k, v in aws_route53_zone.this : k => v.zone_id }
}

output "zone_arns" {
  description = "Map of zone key → hosted zone ARN."
  value       = { for k, v in aws_route53_zone.this : k => v.arn }
}

output "zone_name_servers" {
  description = "Map of zone key → list of name servers. Use these to update NS records in parent zone or registrar."
  value       = { for k, v in aws_route53_zone.this : k => v.name_servers }
}

output "effective_zone_ids" {
  description = "Map of zone key → resolved zone ID (BYO or module-created)."
  value       = local.zone_id_map
}

# ── Delegation Sets ───────────────────────────────────────────────────────────

output "delegation_set_ids" {
  description = "Map of delegation set key → delegation set ID."
  value       = { for k, v in aws_route53_delegation_set.this : k => v.id }
}

output "delegation_set_name_servers" {
  description = "Map of delegation set key → name servers. Set these at your registrar for consistent NS across envs."
  value       = { for k, v in aws_route53_delegation_set.this : k => v.name_servers }
}

# ── DNS Records ───────────────────────────────────────────────────────────────

output "record_fqdns" {
  description = "Map of record key → fully-qualified domain name."
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

output "record_names" {
  description = "Map of record key → record name."
  value       = { for k, v in aws_route53_record.this : k => v.name }
}

# ── Health Checks ─────────────────────────────────────────────────────────────

output "health_check_ids" {
  description = "Map of health check key → health check ID."
  value       = { for k, v in aws_route53_health_check.endpoint : k => v.id }
}

output "calculated_health_check_ids" {
  description = "Map of calculated health check key → health check ID."
  value       = { for k, v in aws_route53_health_check.calculated : k => v.id }
}

output "cloudwatch_health_check_ids" {
  description = "Map of CloudWatch alarm health check key → health check ID."
  value       = { for k, v in aws_route53_health_check.cloudwatch_alarm : k => v.id }
}

# ── DNSSEC ────────────────────────────────────────────────────────────────────

output "dnssec_ds_records" {
  description = "Map of zone key → DS record value to add to the parent zone/registrar. Required to complete DNSSEC setup."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.ds_record }
}

output "dnssec_dnskey_records" {
  description = "Map of zone key → DNSKEY record value."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.dnskey_record }
}

# ── Resolver ──────────────────────────────────────────────────────────────────

output "resolver_endpoint_ids" {
  description = "Map of endpoint key → resolver endpoint ID."
  value       = { for k, v in aws_route53_resolver_endpoint.this : k => v.id }
}

output "resolver_endpoint_ips" {
  description = "Map of endpoint key → list of IP addresses assigned to the endpoint."
  value       = { for k, v in aws_route53_resolver_endpoint.this : k => v.ip_address[*].ip }
}

output "resolver_rule_ids" {
  description = "Map of rule key → resolver rule ID."
  value       = { for k, v in aws_route53_resolver_rule.this : k => v.id }
}

output "resolver_rule_arns" {
  description = "Map of rule key → resolver rule ARN. Use to share rules cross-account via RAM."
  value       = { for k, v in aws_route53_resolver_rule.this : k => v.arn }
}

# ── DNS Firewall ──────────────────────────────────────────────────────────────

output "dns_firewall_rule_group_ids" {
  description = "Map of rule group key → DNS Firewall rule group ID."
  value       = { for k, v in aws_route53_resolver_firewall_rule_group.this : k => v.id }
}

output "dns_firewall_domain_list_ids" {
  description = "Map of domain list key → DNS Firewall domain list ID."
  value       = { for k, v in aws_route53_resolver_firewall_domain_list.this : k => v.id }
}

# ── CIDR Collections ──────────────────────────────────────────────────────────

output "cidr_collection_ids" {
  description = "Map of CIDR collection key → collection ID. Reference in IP-based routing records."
  value       = { for k, v in aws_route53_cidr_collection.this : k => v.id }
}
