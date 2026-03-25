# =============================================================================
# tf-aws-route53 — Core Variables
# =============================================================================

# ── Naming & Tagging ──────────────────────────────────────────────────────────

variable "name" {
  description = "Base name used to prefix resources created by this module."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix: <prefix>-<name>. Example: 'prod' → 'prod-myapp'."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod). Added to all resource tags."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}
