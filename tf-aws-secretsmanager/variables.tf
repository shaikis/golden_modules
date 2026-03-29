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
  description = "Secret value as a plain string. Sensitive. Mutually exclusive with secret_string_map and generate_random_password."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_string_map" {
  description = <<-EOT
    Secret value as a key-value map — automatically JSON-encoded before storage.
    Use this for structured secrets (DB credentials, API keys, etc.):

      secret_string_map = {
        username = "admin"
        password = "changeme"
        host     = "db.example.com"
      }

    Mutually exclusive with secret_string and generate_random_password.
    Sensitive — does not appear in Terraform plan output.
  EOT
  type      = map(string)
  default   = null
  sensitive = true
}

variable "secret_binary" {
  description = "Secret value as base64 binary. Sensitive."
  type        = string
  default     = null
  sensitive   = true
}

variable "generate_random_password" {
  description = <<-EOT
    When true, generates a cryptographically random password and stores it
    as the secret value. The generated password is also available via
    output.generated_password (sensitive).

    Control complexity with random_password_length, random_password_special,
    and random_password_override_special.

    Mutually exclusive with secret_string and secret_string_map.
  EOT
  type    = bool
  default = false
}

variable "random_password_length" {
  description = "Length of the generated random password. Minimum 8."
  type        = number
  default     = 32
  validation {
    condition     = var.random_password_length >= 8
    error_message = "random_password_length must be at least 8."
  }
}

variable "random_password_special" {
  description = "Include special characters in the generated password."
  type        = bool
  default     = true
}

variable "random_password_override_special" {
  description = <<-EOT
    Override the set of special characters used. Defaults to the Terraform
    random_password default set. Useful when the target system forbids
    certain characters (e.g. some DBs reject @ or /).
    Example: "!#$%&*()-_=+[]{}<>:?"
  EOT
  type    = string
  default = null
}

variable "random_password_min_upper" {
  description = "Minimum number of uppercase characters in generated password."
  type        = number
  default     = 1
}

variable "random_password_min_lower" {
  description = "Minimum number of lowercase characters in generated password."
  type        = number
  default     = 1
}

variable "random_password_min_numeric" {
  description = "Minimum number of numeric characters in generated password."
  type        = number
  default     = 1
}

variable "random_password_min_special" {
  description = "Minimum number of special characters in generated password. Only applies when random_password_special = true."
  type        = number
  default     = 1
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
