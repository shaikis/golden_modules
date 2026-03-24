output "zone_id" {
  description = "The hosted zone ID."
  value       = module.route53.zone_ids["main"]
}

output "zone_name_servers" {
  description = "Name servers for the hosted zone. Update these at your domain registrar."
  value       = module.route53.zone_name_servers["main"]
}

output "record_fqdns" {
  description = "All record FQDNs created by this example."
  value       = module.route53.record_fqdns
}
