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
