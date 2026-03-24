# ── Feature Gates ─────────────────────────────────────────────────────────────
# Only resources you opt into will be created.
# Minimum: define environments {} and the module creates MWAA environments + IAM role.

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for MWAA environment metrics."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Set true to auto-create the MWAA execution IAM role. Set false to pass your own role_arn."
  type        = bool
  default     = true
}

# ── Global ────────────────────────────────────────────────────────────────────

variable "name_prefix" {
  description = "Prefix added to all resource names to ensure uniqueness."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Default tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}

# ── BYO ───────────────────────────────────────────────────────────────────────

variable "role_arn" {
  description = "BYO IAM role ARN for MWAA execution (from tf-aws-iam). Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "BYO KMS key ARN (from tf-aws-kms) for MWAA environment encryption."
  type        = string
  default     = null
}

# ── Alarms ────────────────────────────────────────────────────────────────────

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to receive CloudWatch alarm notifications. Required when create_alarms = true."
  type        = string
  default     = null
}

variable "alarm_queued_tasks_threshold" {
  description = "QueuedTasks threshold — alarm fires when tasks waiting exceeds this value."
  type        = number
  default     = 10
}

variable "alarm_pending_tasks_threshold" {
  description = "TasksPending threshold."
  type        = number
  default     = 10
}

variable "alarm_dag_parse_time_threshold" {
  description = "DAGFileProcessingTotalParseTime threshold in seconds."
  type        = number
  default     = 30
}

# ── IAM Permission Toggles ────────────────────────────────────────────────────
# Only relevant when create_iam_role = true.

variable "enable_glue_permissions" {
  description = "Grant the MWAA execution role permission to trigger Glue jobs (for DAGs orchestrating Glue)."
  type        = bool
  default     = false
}

variable "enable_emr_permissions" {
  description = "Grant the MWAA execution role permission to manage EMR clusters."
  type        = bool
  default     = false
}

variable "enable_redshift_permissions" {
  description = "Grant the MWAA execution role permission to interact with Redshift."
  type        = bool
  default     = false
}

variable "enable_sagemaker_permissions" {
  description = "Grant the MWAA execution role permission to execute SageMaker pipelines."
  type        = bool
  default     = false
}

variable "enable_batch_permissions" {
  description = "Grant the MWAA execution role permission to submit AWS Batch jobs."
  type        = bool
  default     = false
}

variable "enable_lambda_permissions" {
  description = "Grant the MWAA execution role permission to invoke Lambda functions."
  type        = bool
  default     = false
}

variable "enable_sfn_permissions" {
  description = "Grant the MWAA execution role permission to start Step Functions executions."
  type        = bool
  default     = false
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the MWAA execution role."
  type        = list(string)
  default     = []
}

# ── MWAA Environments ─────────────────────────────────────────────────────────

variable "environments" {
  description = "Map of MWAA environments to create."
  type = map(object({
    airflow_version   = optional(string, "2.8.1")
    environment_class = optional(string, "mw1.medium") # mw1.small | mw1.medium | mw1.large | mw1.xlarge | mw1.2xlarge
    max_workers       = optional(number, 10)
    min_workers       = optional(number, 1)
    schedulers        = optional(number, 2)

    source_bucket_arn                = string
    dag_s3_path                      = optional(string, "dags/")
    requirements_s3_path             = optional(string, null)
    requirements_s3_object_version   = optional(string, null)
    plugins_s3_path                  = optional(string, null)
    plugins_s3_object_version        = optional(string, null)
    startup_script_s3_path           = optional(string, null)
    startup_script_s3_object_version = optional(string, null)

    execution_role_arn = optional(string, null) # null = use module-created role
    kms_key            = optional(string, null) # null = use module-level kms_key_arn or AWS-managed

    webserver_access_mode           = optional(string, "PRIVATE_ONLY") # PUBLIC_ONLY | PRIVATE_ONLY
    weekly_maintenance_window_start = optional(string, "MON:01:00")

    subnet_ids         = list(string)
    security_group_ids = list(string)

    airflow_configuration_options = optional(map(string), {})

    # Logging levels per component
    dag_processing_logs_level = optional(string, "WARNING") # CRITICAL | ERROR | WARNING | INFO | DEBUG
    scheduler_logs_level      = optional(string, "WARNING")
    task_logs_level           = optional(string, "INFO")
    webserver_logs_level      = optional(string, "WARNING")
    worker_logs_level         = optional(string, "WARNING")

    tags = optional(map(string), {})
  }))
  default = {}
}
