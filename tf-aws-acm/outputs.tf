output "certificate_arn" {
  description = "ARN of the issued ACM certificate. Use this in ALB listeners and CloudFront distributions."
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain" {
  description = "Primary domain name of the certificate."
  value       = aws_acm_certificate.this.domain_name
}

output "certificate_status" {
  description = "Current status of the certificate: PENDING_VALIDATION, ISSUED, FAILED, etc."
  value       = aws_acm_certificate.this.status
}

output "certificate_id" {
  description = "ID of the ACM certificate resource."
  value       = aws_acm_certificate.this.id
}

output "domain_validation_options" {
  description = "Domain validation options — CNAME name/value pairs needed for DNS validation."
  value       = aws_acm_certificate.this.domain_validation_options
}

output "validation_record_fqdns" {
  description = "FQDNs of the Route 53 DNS validation records created."
  value       = [for record in aws_route53_record.validation : record.fqdn]
}

output "certificate_not_after" {
  description = "Expiry date of the certificate (RFC3339). Use with CloudWatch to alert before expiry."
  value       = aws_acm_certificate.this.not_after
}

output "certificate_not_before" {
  description = "Issuance date of the certificate (RFC3339)."
  value       = aws_acm_certificate.this.not_before
}

output "certificate_type" {
  description = "Certificate type: AMAZON_ISSUED or PRIVATE."
  value       = aws_acm_certificate.this.type
}

output "certificate_key_algorithm" {
  description = "Key algorithm used: RSA_2048, EC_prime256v1, etc."
  value       = aws_acm_certificate.this.key_algorithm
}

output "renewed_certificate_arn" {
  description = "ARN of the renewed certificate when early_renewal_duration is set and renewal occurs."
  value       = aws_acm_certificate.this.renewed_certificate_arn
}
