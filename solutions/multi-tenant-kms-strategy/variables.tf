variable "name_prefix" {
  description = "Prefix used for solution resource names."
  type        = string
  default     = "prod"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project tag value."
  type        = string
  default     = "multi-tenant-kms"
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

variable "central_region" {
  description = "Region for the central key management account."
  type        = string
  default     = "us-east-1"
}

variable "workload_region" {
  description = "Region for the workload account."
  type        = string
  default     = "us-east-1"
}

variable "central_profile" {
  description = "Optional AWS profile for the central account provider."
  type        = string
  default     = null
}

variable "workload_profile" {
  description = "Optional AWS profile for the workload account provider."
  type        = string
  default     = null
}

variable "tenant_ids" {
  description = "Tenant IDs to provision one customer managed KMS key per tenant."
  type        = list(string)
  default     = ["tenant-001", "tenant-002"]

  validation {
    condition     = length(var.tenant_ids) > 0
    error_message = "tenant_ids must contain at least one tenant."
  }
}

variable "dynamodb_kms_key_arn" {
  description = "Optional KMS key ARN for DynamoDB server-side encryption. Client-side encryption still uses tenant KMS keys."
  type        = string
  default     = null
}
