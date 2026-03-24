output "bucket_id" { value = aws_s3_bucket.this.id }
output "bucket_arn" { value = aws_s3_bucket.this.arn }
output "bucket_name" { value = aws_s3_bucket.this.bucket }

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name for CloudFront origins."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_website_endpoint" {
  description = "Website endpoint (if static hosting enabled)."
  value       = length(aws_s3_bucket_website_configuration.this) > 0 ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}
