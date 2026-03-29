output "web_acl_id" {
  description = "WebACL ID."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "WebACL ARN (use this when associating with CloudFront or ALB/API GW)."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "WebACL name."
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "WebACL capacity units consumed."
  value       = aws_wafv2_web_acl.this.capacity
}

output "ip_set_arns" {
  description = "Map of IP set key to ARN."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.arn }
}

output "regex_pattern_set_arns" {
  description = "Map of regex pattern set key to ARN."
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.arn }
}
