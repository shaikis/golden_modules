output "zone_id" {
  description = "The hosted zone ID."
  value       = module.route53.zone_ids["main"]
}

output "zone_name_servers" {
  description = "Name servers — update at your registrar."
  value       = module.route53.zone_name_servers["main"]
}

output "health_check_ids" {
  description = "Map of all endpoint health check IDs."
  value       = module.route53.health_check_ids
}

output "calculated_health_check_ids" {
  description = "Map of calculated (combined) health check IDs."
  value       = module.route53.calculated_health_check_ids
}

output "record_fqdns" {
  description = "All record FQDNs created by this example."
  value       = module.route53.record_fqdns
}
