output "access_point_arns" {
  description = "ARNs of the created access points."
  value       = { for name, access_point in aws_s3_access_point.this : name => access_point.arn }
}

output "access_point_aliases" {
  description = "Aliases of the created access points."
  value       = { for name, access_point in aws_s3_access_point.this : name => access_point.alias }
}

output "access_point_domain_names" {
  description = "Domain names of the created access points."
  value       = { for name, access_point in aws_s3_access_point.this : name => access_point.domain_name }
}

output "access_point_endpoints" {
  description = "Endpoints of the created access points."
  value       = { for name, access_point in aws_s3_access_point.this : name => access_point.endpoints }
}
