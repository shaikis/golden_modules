output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name (e.g. d111111abcdef8.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront Route 53 hosted zone ID (use in Route53 alias records)."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_etag" {
  description = "Current version (ETag) of the distribution configuration."
  value       = aws_cloudfront_distribution.this.etag
}

output "distribution_status" {
  description = "Deployment status: Deployed or InProgress."
  value       = aws_cloudfront_distribution.this.status
}

output "origin_access_control_ids" {
  description = "Map of OAC key to OAC ID."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.id }
}

output "cloudfront_function_arns" {
  description = "Map of CloudFront Function key to ARN."
  value       = { for k, v in aws_cloudfront_function.this : k => v.arn }
}

output "realtime_log_config_arn" {
  description = "Real-time log configuration ARN (null when disabled)."
  value       = try(aws_cloudfront_realtime_log_config.this[0].arn, null)
}
