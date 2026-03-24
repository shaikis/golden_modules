variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = ""
}
variable "owner" {
  type    = string
  default = ""
}
variable "cost_center" {
  type    = string
  default = ""
}
variable "tags" {
  type = map(string)
  default = {
  }
}

variable "description" {
  type    = string
  default = "Managed by Terraform"
}
variable "kms_key_id" {
  type    = string
  default = null
}
variable "recovery_window_days" {
  type    = number
  default = 30
}
variable "force_overwrite_replica_secret" {
  type    = bool
  default = false
}

variable "secret_string" {
  description = "Secret value as a plain string. Sensitive."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_binary" {
  description = "Secret value as base64 binary. Sensitive."
  type        = string
  default     = null
  sensitive   = true
}

variable "rotation_lambda_arn" {
  description = "Lambda ARN for automatic rotation."
  type        = string
  default     = null
}

variable "rotation_rules" {
  description = "Rotation schedule."
  type = object({
    automatically_after_days = optional(number, null)
    schedule_expression      = optional(string, null)
    duration                 = optional(string, null)
  })
  default = null
}

variable "policy" {
  description = "Resource-based policy JSON."
  type        = string
  default     = ""
}

variable "replicas" {
  description = "Map of replica regions."
  type = map(object({
    kms_key_id = optional(string, null)
  }))
  default = {}
}
