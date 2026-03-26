# ============================================================
#  Feature Gates
# ============================================================

variable "create_domains" {
  type        = bool
  default     = false
  description = "Create SageMaker Studio domains."
}

variable "create_notebooks" {
  type        = bool
  default     = false
  description = "Create SageMaker notebook instances."
}

variable "create_models" {
  type        = bool
  default     = false
  description = "Create SageMaker models."
}

variable "create_endpoints" {
  type        = bool
  default     = false
  description = "Create SageMaker endpoints and endpoint configs."
}

variable "create_feature_groups" {
  type        = bool
  default     = false
  description = "Create SageMaker Feature Store feature groups."
}

variable "create_pipelines" {
  type        = bool
  default     = false
  description = "Create SageMaker Pipelines."
}

variable "create_alarms" {
  type        = bool
  default     = false
  description = "Create CloudWatch alarms for SageMaker endpoints."
}

variable "create_iam_role" {
  type        = bool
  default     = true
  description = "Auto-create SageMaker execution role. Set false to provide role_arn."
}

# ============================================================
#  BYO (Bring Your Own) Foundational Resources
# ============================================================

variable "role_arn" {
  type        = string
  default     = null
  description = "Existing IAM role ARN from tf-aws-iam. Used when create_iam_role = false."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key ARN from tf-aws-kms for notebook/model/endpoint encryption."
}

# ============================================================
#  Global
# ============================================================

variable "name_prefix" {
  type        = string
  default     = ""
  description = "Prefix for all resource names."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

# ============================================================
#  Domains
# ============================================================

variable "domains" {
  description = "Map of SageMaker Studio domains."
  type = map(object({
    auth_mode               = optional(string, "IAM")
    vpc_id                  = optional(string, null)
    subnet_ids              = optional(list(string), [])
    app_network_access_type = optional(string, "PublicInternetOnly")
    tags                    = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.domains :
      contains(["IAM", "SSO"], v.auth_mode)
    ])
    error_message = "Each domain auth_mode must be either 'IAM' or 'SSO'."
  }

  validation {
    condition = alltrue([
      for k, v in var.domains :
      contains(["PublicInternetOnly", "VpcOnly"], v.app_network_access_type)
    ])
    error_message = "Each domain app_network_access_type must be 'PublicInternetOnly' or 'VpcOnly'."
  }
}

# ============================================================
#  Notebooks
# ============================================================

variable "notebooks" {
  description = "Map of SageMaker notebook instances."
  type = map(object({
    instance_type       = optional(string, "ml.t3.medium")
    platform_identifier = optional(string, "notebook-al2-v2")
    volume_size_in_gb   = optional(number, 20)
    subnet_id           = optional(string, null)
    security_groups     = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.notebooks :
      can(regex("^ml\\.", v.instance_type))
    ])
    error_message = "Each notebook instance_type must begin with 'ml.' (e.g. ml.t3.medium)."
  }
}

# ============================================================
#  Models
# ============================================================

variable "models" {
  description = "Map of SageMaker models."
  type = map(object({
    execution_role_arn      = optional(string, null)
    primary_container_image = string
    model_data_url          = optional(string, null)
    environment             = optional(map(string), {})
    tags                    = optional(map(string), {})
  }))
  default = {}
}

# ============================================================
#  Endpoints
# ============================================================

variable "endpoint_configs" {
  description = "Map of SageMaker endpoint configurations."
  type = map(object({
    production_variants = list(object({
      variant_name           = string
      model_name             = string
      instance_type          = optional(string, "ml.t2.medium")
      initial_instance_count = optional(number, 1)
      initial_variant_weight = optional(number, 1.0)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "endpoints" {
  description = "Map of SageMaker endpoints."
  type = map(object({
    endpoint_config_name = string
    tags                 = optional(map(string), {})
  }))
  default = {}
}

# ============================================================
#  Feature Groups
# ============================================================

variable "feature_groups" {
  description = "Map of SageMaker Feature Store feature groups."
  type = map(object({
    record_identifier_name  = string
    event_time_feature_name = string
    enable_online_store     = optional(bool, true)
    enable_offline_store    = optional(bool, false)
    s3_offline_store_uri    = optional(string, null)
    features = list(object({
      name         = string
      feature_type = string # Integral, Fractional, or String
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.feature_groups :
      alltrue([
        for f in v.features :
        contains(["Integral", "Fractional", "String"], f.feature_type)
      ])
    ])
    error_message = "Each feature's feature_type must be one of: Integral, Fractional, String."
  }
}

# ============================================================
#  Pipelines
# ============================================================

variable "pipelines" {
  description = "Map of SageMaker Pipelines."
  type = map(object({
    pipeline_definition = string # JSON pipeline definition
    description         = optional(string, null)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ============================================================
#  Alarms
# ============================================================

variable "alarm_sns_arns" {
  description = "SNS topic ARNs for CloudWatch alarm notifications."
  type        = list(string)
  default     = []
}
