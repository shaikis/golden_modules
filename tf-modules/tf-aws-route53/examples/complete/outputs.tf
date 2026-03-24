# =============================================================================
# Complete Example — Outputs
# =============================================================================

# ── Zones ─────────────────────────────────────────────────────────────────────

output "public_zone_id" {
  description = "The public hosted zone ID."
  value       = module.route53.zone_ids["public"]
}

output "private_zone_id" {
  description = "The private hosted zone ID."
  value       = module.route53.zone_ids["private"]
}

output "public_zone_name_servers" {
  description = "Name servers for the public zone — update at your registrar."
  value       = module.route53.zone_name_servers["public"]
}

# ── Delegation Sets ───────────────────────────────────────────────────────────

output "delegation_set_name_servers" {
  description = "Name servers from the reusable delegation set — pin these at your registrar."
  value       = module.route53.delegation_set_name_servers
}

# ── Records ───────────────────────────────────────────────────────────────────

output "record_fqdns" {
  description = "Map of all record FQDNs created."
  value       = module.route53.record_fqdns
}

# ── Health Checks ─────────────────────────────────────────────────────────────

output "health_check_ids" {
  description = "Endpoint health check IDs."
  value       = module.route53.health_check_ids
}

output "calculated_health_check_ids" {
  description = "Calculated health check IDs."
  value       = module.route53.calculated_health_check_ids
}

output "cloudwatch_health_check_ids" {
  description = "CloudWatch alarm health check IDs."
  value       = module.route53.cloudwatch_health_check_ids
}

# ── DNSSEC ────────────────────────────────────────────────────────────────────

output "dnssec_ds_records" {
  description = "DS record values — add these to your parent zone / registrar to complete DNSSEC chain."
  value       = module.route53.dnssec_ds_records
}

# ── Resolver ──────────────────────────────────────────────────────────────────

output "resolver_inbound_endpoint_ips" {
  description = "IPs assigned to the inbound resolver endpoint — configure these on on-premises DNS forwarders."
  value       = try(module.route53.resolver_endpoint_ips["inbound"], [])
}

output "resolver_outbound_endpoint_id" {
  description = "Outbound resolver endpoint ID."
  value       = try(module.route53.resolver_endpoint_ids["outbound"], null)
}

output "resolver_rule_ids" {
  description = "Resolver forwarding rule IDs."
  value       = module.route53.resolver_rule_ids
}

# ── DNS Firewall ──────────────────────────────────────────────────────────────

output "dns_firewall_rule_group_ids" {
  description = "DNS Firewall rule group IDs."
  value       = module.route53.dns_firewall_rule_group_ids
}

output "dns_firewall_domain_list_ids" {
  description = "DNS Firewall domain list IDs."
  value       = module.route53.dns_firewall_domain_list_ids
}

# ── CIDR Collections ──────────────────────────────────────────────────────────

output "cidr_collection_ids" {
  description = "CIDR collection IDs for IP-based routing."
  value       = module.route53.cidr_collection_ids
}
