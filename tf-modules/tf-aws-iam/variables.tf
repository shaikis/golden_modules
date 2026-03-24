variable "name_prefix" {
  description = "Prefix prepended to all auto-generated resource names."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Roles
# ---------------------------------------------------------------------------

variable "roles" {
  description = "Map of IAM roles to create. Key becomes the role identifier in outputs."
  type = map(object({
    # Naming
    name        = optional(string, null) # null = auto-generate from <name_prefix>-<key>
    description = optional(string, null)
    path        = optional(string, "/")

    # Behaviour
    max_session_duration    = optional(number, 3600)
    force_detach_policies   = optional(bool, true)
    permission_boundary_arn = optional(string, null)

    # Trust policy — at least one of these must be provided
    service_principals   = optional(list(string), []) # e.g. ["glue.amazonaws.com"]
    aws_principals       = optional(list(string), []) # e.g. ["arn:aws:iam::123456789012:root"]
    federated_principals = optional(list(string), []) # OIDC/SAML provider ARNs

    # Conditions for OIDC / federated trust (GitHub Actions, EKS IRSA, etc.)
    oidc_conditions = optional(list(object({
      test     = string       # e.g. "StringLike" or "StringEquals"
      variable = string       # e.g. "token.actions.githubusercontent.com:sub"
      values   = list(string) # e.g. ["repo:myorg/myrepo:*"]
    })), [])

    # Policies to attach
    managed_policy_arns = optional(list(string), []) # AWS managed + customer managed ARNs

    # Feature gate: create EC2 instance profile alongside this role
    create_instance_profile = optional(bool, false)

    # Inline policies: map of policy_name → JSON string
    inline_policies = optional(map(string), {})

    # Per-role tags (merged with module-level var.tags)
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Standalone managed policies
# ---------------------------------------------------------------------------

variable "policies" {
  description = "Standalone customer-managed IAM policies to create."
  type = map(object({
    name        = optional(string, null) # null = auto-generate from <name_prefix>-<key>
    description = optional(string, null)
    path        = optional(string, "/")
    policy_json = string
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# OIDC providers
# ---------------------------------------------------------------------------

variable "oidc_providers" {
  description = "OIDC identity providers to register in IAM."
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Permission boundaries
# ---------------------------------------------------------------------------

variable "permission_boundaries" {
  description = "Permission boundary policies to create."
  type = map(object({
    name        = optional(string, null)
    description = optional(string, null)
    path        = optional(string, "/")
    policy_json = string
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Convenience inputs for reusable policy document generation
# ---------------------------------------------------------------------------

variable "data_lake_bucket_arns" {
  description = "S3 bucket ARNs used by the data_lake_read / data_lake_write policy locals."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "KMS key ARNs used by the kms_usage policy local."
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "Secrets Manager secret ARNs used by the secrets_manager_read policy local."
  type        = list(string)
  default     = []
}

variable "ssm_parameter_paths" {
  description = "SSM Parameter Store path ARNs used by the ssm_parameter_read policy local."
  type        = list(string)
  default     = []
}
