variable "name" {
  description = "Name identifier for the certificate (used in tags only)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "Primary domain name for the certificate (e.g. example.com or *.example.com)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names (SANs) to include in the certificate."
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Certificate validation method: DNS or EMAIL. DNS is recommended — fully automated via Route 53."
  type        = string
  default     = "DNS"
  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "validation_method must be DNS or EMAIL."
  }
}

variable "route53_zone_id" {
  description = "Route 53 Hosted Zone ID for DNS validation record creation. Required when validation_method = DNS."
  type        = string
  default     = null
}

variable "wait_for_validation" {
  description = "Block until the certificate is fully validated and issued. Set false for async workflows."
  type        = bool
  default     = true
}

variable "key_algorithm" {
  description = "Certificate key algorithm: RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1."
  type        = string
  default     = "RSA_2048"
  validation {
    condition     = contains(["RSA_2048", "RSA_4096", "EC_prime256v1", "EC_secp384r1"], var.key_algorithm)
    error_message = "Invalid key_algorithm."
  }
}

variable "transparency_logging" {
  description = "Enable certificate transparency logging. Required by modern browsers."
  type        = bool
  default     = true
}

variable "certificate_authority_arn" {
  description = <<-EOT
    ARN of an AWS Private Certificate Authority (PCA) to use when issuing a
    private certificate. When set, validation_method is ignored — Private CA
    certificates are issued immediately without DNS/email validation.
    Leave null (default) to request a public ACM certificate.
  EOT
  type    = string
  default = null
}

variable "route53_zone_ids" {
  description = <<-EOT
    Map of domain name → Route 53 Hosted Zone ID for DNS validation.
    Use this when the primary domain and SANs live in different hosted zones.

    Example:
      route53_zone_ids = {
        "example.com"     = "Z1234567890ABC"
        "api.other.com"   = "Z0987654321XYZ"
      }

    When set, this takes precedence over route53_zone_id.
    When not set, route53_zone_id is used for ALL validation records.
  EOT
  type    = map(string)
  default = {}
}

variable "early_renewal_duration" {
  description = <<-EOT
    Specifies the number of days before expiry to attempt renewal.
    ACM auto-renews public certificates, but this triggers Terraform to
    replace the certificate resource early (useful for Private CA certs).
    Format: "p30d" (30 days), "p1m" (1 month). Leave null to disable.
  EOT
  type    = string
  default = null
}
