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
  type    = map(string)
  default = {}
}

variable "description" {
  description = "Description of the IAM role."
  type        = string
  default     = "Managed by Terraform"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600–43200)."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200."
  }
}

variable "force_detach_policies" {
  description = "Force detach policies before destroying."
  type        = bool
  default     = true
}

variable "permissions_boundary" {
  description = "ARN of the IAM permissions boundary policy."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Trust Policy (assume role)
# ---------------------------------------------------------------------------
variable "trusted_role_arns" {
  description = "IAM role ARNs that can assume this role."
  type        = list(string)
  default     = []
}

variable "trusted_role_services" {
  description = "AWS services that can assume this role (e.g., ec2.amazonaws.com)."
  type        = list(string)
  default     = []
}

variable "trusted_role_actions" {
  description = "Override the sts actions in the trust policy."
  type        = list(string)
  default     = ["sts:AssumeRole"]
}

variable "assume_role_conditions" {
  description = "List of conditions for the trust policy."
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  default = []
}

variable "custom_trust_policy" {
  description = "Fully custom trust policy JSON (overrides built-in generation)."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Policies
# ---------------------------------------------------------------------------
variable "managed_policy_arns" {
  description = "List of AWS managed or customer-managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy name → JSON document."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Instance Profile
# ---------------------------------------------------------------------------
variable "create_instance_profile" {
  description = "Create an EC2 instance profile for this role."
  type        = bool
  default     = false
}
