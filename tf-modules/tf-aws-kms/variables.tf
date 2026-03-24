# ---------------------------------------------------------------------------
# Naming & Tagging
# ---------------------------------------------------------------------------
variable "name_prefix" {
  description = "Prefix prepended to every key alias: alias/<name_prefix>/<key_name>."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Keys
# ---------------------------------------------------------------------------
variable "keys" {
  description = "Map of KMS keys to create. Key name becomes part of the alias."
  type = map(object({
    description              = optional(string, null)
    key_usage                = optional(string, "ENCRYPT_DECRYPT")
    customer_master_key_spec = optional(string, "SYMMETRIC_DEFAULT")
    enable_key_rotation      = optional(bool, true)
    rotation_period_in_days  = optional(number, 365)
    deletion_window_in_days  = optional(number, 30)
    is_enabled               = optional(bool, true)
    multi_region             = optional(bool, false)

    # Key policy principals
    admin_principals         = optional(list(string), [])
    user_principals          = optional(list(string), [])
    service_principals       = optional(list(string), [])
    cross_account_principals = optional(list(string), [])

    # Extra aliases beyond the auto-generated alias/<name_prefix>/<key_name>
    additional_aliases = optional(list(string), [])

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Replica Keys
# ---------------------------------------------------------------------------
variable "replica_keys" {
  description = "Multi-region replica keys. primary_key_arn must come from another region."
  type = map(object({
    primary_key_arn         = string
    description             = optional(string, null)
    deletion_window_in_days = optional(number, 30)
    enabled                 = optional(bool, true)
    admin_principals        = optional(list(string), [])
    user_principals         = optional(list(string), [])
    tags                    = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Grants
# ---------------------------------------------------------------------------
variable "grants" {
  description = "KMS grants for AWS services or cross-account principals."
  type = map(object({
    key_name                  = string
    grantee_principal         = string
    operations                = list(string)
    retiring_principal        = optional(string, null)
    encryption_context_equals = optional(map(string), null)
    encryption_context_subset = optional(map(string), null)
  }))
  default = {}
}
