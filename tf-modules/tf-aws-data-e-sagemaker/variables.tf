# ---------------------------------------------------------------------------
# Feature Gates
# ---------------------------------------------------------------------------

variable "create_pipelines" {
  description = "Set true to create SageMaker Pipelines."
  type        = bool
  default     = false
}

variable "create_models" {
  description = "Set true to create SageMaker Models."
  type        = bool
  default     = false
}

variable "create_endpoints" {
  description = "Set true to create SageMaker Endpoint Configurations and Endpoints."
  type        = bool
  default     = false
}

variable "create_feature_groups" {
  description = "Set true to create SageMaker Feature Groups."
  type        = bool
  default     = false
}

variable "create_user_profiles" {
  description = "Set true to create SageMaker Studio User Profiles."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for SageMaker endpoints."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Set true to auto-create the SageMaker execution IAM role. Set false to pass your own role_arn."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO Foundational
# ---------------------------------------------------------------------------

variable "role_arn" {
  description = "Existing SageMaker execution role ARN (used when create_iam_role = false)."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN from tf-aws-kms to encrypt SageMaker resources."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "data_bucket_arns" {
  description = "List of S3 bucket ARNs that the SageMaker role may read/write (data, models, feature store)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Global Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Optional prefix prepended to auto-generated resource names."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------

variable "sagemaker_role_name" {
  description = "Override the auto-generated name for the SageMaker execution role."
  type        = string
  default     = null
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the SageMaker execution role."
  type        = list(string)
  default     = []
}

variable "enable_ecr_access" {
  description = "Attach ECR read permissions to the SageMaker role (needed for custom containers)."
  type        = bool
  default     = true
}

variable "enable_glue_access" {
  description = "Attach Glue catalog permissions to the SageMaker role (needed for Feature Store offline tables)."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Alarm Thresholds
# ---------------------------------------------------------------------------

variable "alarm_model_latency_p99_ms" {
  description = "ModelLatency p99 threshold in milliseconds before alarm fires."
  type        = number
  default     = 5000
}

variable "alarm_error_rate_threshold" {
  description = "4XX/5XX error count threshold before alarm fires."
  type        = number
  default     = 5
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization percentage threshold before alarm fires."
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory utilization percentage threshold before alarm fires."
  type        = number
  default     = 80
}

variable "alarm_disk_threshold" {
  description = "Disk utilization percentage threshold before alarm fires."
  type        = number
  default     = 80
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms."
  type        = number
  default     = 3
}

variable "alarm_period_seconds" {
  description = "Period in seconds for CloudWatch alarm evaluation."
  type        = number
  default     = 300
}

# ---------------------------------------------------------------------------
# Domains
# ---------------------------------------------------------------------------

variable "domains" {
  description = "Map of SageMaker Studio domains to create."
  type = map(object({
    auth_mode                     = optional(string, "IAM")
    vpc_id                        = string
    subnet_ids                    = list(string)
    execution_role_arn            = optional(string, null)
    app_network_access_type       = optional(string, "VpcOnly")
    app_security_group_management = optional(string, "Service")
    kms_key_id                    = optional(string, null)
    security_group_ids            = optional(list(string), [])
    tags                          = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Pipelines
# ---------------------------------------------------------------------------

variable "pipelines" {
  description = "Map of SageMaker Pipelines to create (requires create_pipelines = true)."
  type = map(object({
    display_name        = optional(string, null)
    description         = optional(string, null)
    role_arn            = optional(string, null)
    pipeline_definition = string
    max_parallel_steps  = optional(number, null)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

variable "models" {
  description = "Map of SageMaker Models to create (requires create_models = true)."
  type = map(object({
    execution_role_arn       = optional(string, null)
    enable_network_isolation = optional(bool, false)
    vpc_subnet_ids           = optional(list(string), [])
    vpc_security_group_ids   = optional(list(string), [])
    primary_container = object({
      image_uri      = string
      model_data_url = optional(string, null)
      mode           = optional(string, "SingleModel")
      environment    = optional(map(string), {})
    })
    containers = optional(list(object({
      image_uri      = string
      model_data_url = optional(string, null)
      mode           = optional(string, "SingleModel")
      environment    = optional(map(string), {})
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Endpoint Configurations & Endpoints
# ---------------------------------------------------------------------------

variable "endpoint_configurations" {
  description = "Map of SageMaker Endpoint Configurations (requires create_endpoints = true)."
  type = map(object({
    kms_key_arn = optional(string, null)
    production_variants = list(object({
      variant_name           = string
      model_key              = string
      instance_type          = optional(string, "ml.m5.xlarge")
      initial_instance_count = optional(number, 1)
      initial_variant_weight = optional(number, 1)
    }))
    data_capture_enabled             = optional(bool, false)
    data_capture_s3_uri              = optional(string, null)
    data_capture_sample_percentage   = optional(number, 10)
    data_capture_options             = optional(list(string), ["Input", "Output"])
    async_inference_enabled          = optional(bool, false)
    async_output_s3_uri              = optional(string, null)
    async_failure_s3_uri             = optional(string, null)
    async_max_concurrent_invocations = optional(number, null)
    tags                             = optional(map(string), {})
  }))
  default = {}
}

variable "endpoints" {
  description = "Map of SageMaker Endpoints to create (requires create_endpoints = true)."
  type = map(object({
    endpoint_config_key = string
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Feature Groups
# ---------------------------------------------------------------------------

variable "feature_groups" {
  description = "Map of SageMaker Feature Groups (requires create_feature_groups = true)."
  type = map(object({
    record_identifier_feature_name = string
    event_time_feature_name        = string
    role_arn                       = optional(string, null)
    online_store_enabled           = optional(bool, true)
    online_store_kms_key_id        = optional(string, null)
    offline_store_bucket           = optional(string, null)
    offline_store_prefix           = optional(string, null)
    offline_data_format            = optional(string, "Parquet")
    offline_table_format           = optional(string, "Glue")
    disable_glue_table_creation    = optional(bool, false)
    features = list(object({
      name = string
      type = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# User Profiles (Studio)
# ---------------------------------------------------------------------------

variable "user_profiles" {
  description = "Map of SageMaker Studio User Profiles (requires create_user_profiles = true)."
  type = map(object({
    domain_key         = string
    execution_role_arn = optional(string, null)
    security_group_ids = optional(list(string), [])
    tags               = optional(map(string), {})
  }))
  default = {}
}
