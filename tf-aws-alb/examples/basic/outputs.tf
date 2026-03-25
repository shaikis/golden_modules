output "alb_arn" {
  description = "ARN of the ALB."
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route 53 alias records)."
  value       = module.alb.alb_zone_id
}
