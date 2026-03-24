# ── Feature Gates ─────────────────────────────────────────────────────────────
# Only resources you opt into will be created.
# Minimum: define state_machines {} and the module creates state machines + IAM role.

variable "create_activities" {
  description = "Set true to create Step Functions activities defined in the activities map."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for state machine metrics."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Set true to auto-create the Step Functions execution IAM role. Set false to pass your own role_arn."
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
  description = "BYO IAM role ARN for state machine execution (from tf-aws-iam). Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "BYO KMS key ARN (from tf-aws-kms) for encrypting Step Functions resources."
  type        = string
  default     = null
}

# ── Alarms ───────────────────────────────────────────────────────────────────

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to receive CloudWatch alarm notifications. Required when create_alarms = true."
  type        = string
  default     = null
}

variable "alarm_execution_time_threshold_ms" {
  description = "P99 ExecutionTime threshold in milliseconds for STANDARD state machine alarms."
  type        = number
  default     = 300000
}

variable "alarm_express_failure_rate_threshold" {
  description = "ExecutionsFailed rate threshold (%) for EXPRESS state machine alarms."
  type        = number
  default     = 1
}

variable "alarm_express_timeout_rate_threshold" {
  description = "ExecutionsTimedOut rate threshold (%) for EXPRESS state machine alarms."
  type        = number
  default     = 1
}

# ── IAM Permission Toggles ────────────────────────────────────────────────────
# Only relevant when create_iam_role = true.

variable "enable_lambda_permissions" {
  description = "Grant the state machine role permission to invoke Lambda functions."
  type        = bool
  default     = true
}

variable "enable_glue_permissions" {
  description = "Grant the state machine role permission to trigger Glue jobs."
  type        = bool
  default     = false
}

variable "enable_ecs_permissions" {
  description = "Grant the state machine role permission to run ECS tasks."
  type        = bool
  default     = false
}

variable "enable_batch_permissions" {
  description = "Grant the state machine role permission to submit AWS Batch jobs."
  type        = bool
  default     = false
}

variable "enable_sagemaker_permissions" {
  description = "Grant the state machine role permission to execute SageMaker pipelines."
  type        = bool
  default     = false
}

variable "enable_dynamodb_permissions" {
  description = "Grant the state machine role permission to read/write DynamoDB tables."
  type        = bool
  default     = false
}

variable "enable_sns_permissions" {
  description = "Grant the state machine role permission to publish to SNS topics."
  type        = bool
  default     = false
}

variable "enable_sqs_permissions" {
  description = "Grant the state machine role permission to send messages to SQS queues."
  type        = bool
  default     = false
}

variable "enable_emr_permissions" {
  description = "Grant the state machine role permission to perform EMR cluster operations."
  type        = bool
  default     = false
}

variable "enable_sfn_permissions" {
  description = "Grant the state machine role permission to start nested Step Functions workflows."
  type        = bool
  default     = false
}

# ── Scoped ARN Lists ──────────────────────────────────────────────────────────

variable "lambda_function_arns" {
  description = "List of Lambda function ARNs the state machine role may invoke. Empty list = wildcard within account."
  type        = list(string)
  default     = []
}

variable "glue_job_arns" {
  description = "List of Glue job ARNs the state machine role may trigger. Empty list = all Glue jobs."
  type        = list(string)
  default     = []
}

variable "sagemaker_pipeline_arns" {
  description = "List of SageMaker pipeline ARNs the state machine role may execute."
  type        = list(string)
  default     = []
}

variable "ecs_cluster_arns" {
  description = "List of ECS cluster ARNs for task execution permissions."
  type        = list(string)
  default     = []
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs the state machine role may read/write."
  type        = list(string)
  default     = []
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs the state machine role may publish to."
  type        = list(string)
  default     = []
}

variable "sqs_queue_arns" {
  description = "List of SQS queue ARNs the state machine role may send messages to."
  type        = list(string)
  default     = []
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the state machine execution role."
  type        = list(string)
  default     = []
}

# ── State Machines ────────────────────────────────────────────────────────────

variable "state_machines" {
  description = "Map of Step Functions state machines to create."
  type = map(object({
    type       = optional(string, "STANDARD") # STANDARD | EXPRESS
    definition = string                       # JSON ASL
    role_arn   = optional(string, null)       # null = use module-created role

    logging = optional(object({
      level                  = optional(string, "ERROR") # ALL | ERROR | FATAL | OFF
      include_execution_data = optional(bool, false)
      log_group_name         = optional(string, null) # null = auto-create
    }), null)

    tracing_enabled     = optional(bool, false)
    publish             = optional(bool, false)
    version_description = optional(string, null)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ── Activities ────────────────────────────────────────────────────────────────

variable "activities" {
  description = "Map of Step Functions activities to create. Only used when create_activities = true."
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}
