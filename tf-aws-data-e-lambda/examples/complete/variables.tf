variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

# ── Naming & Tagging ──────────────────────────────────────────────────────────
variable "function_name" {
  description = "Lambda function base name."
  type        = string
  default     = "my-api-handler"
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "myapp"
}

variable "owner" {
  description = "Owning team."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center code."
  type        = string
  default     = ""
}

variable "description" {
  description = "Function description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra resource tags."
  type        = map(string)
  default     = {}
}

# ── IAM Role ──────────────────────────────────────────────────────────────────
# BYO Pattern:
#   create_role = true  + role_arn = null  → module creates a new role (default)
#   create_role = false + role_arn = "arn" → use existing role, no new role created
variable "create_role" {
  description = "Auto-create execution role. Set false + role_arn to reuse existing."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Existing IAM execution role ARN. Skips role creation when provided."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Managed policies for the auto-created role."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

variable "inline_policies" {
  description = "Inline policies (name → JSON) for the auto-created role."
  type        = map(string)
  default     = {}
}

# ── Package & Code ────────────────────────────────────────────────────────────
variable "package_type" {
  description = "Zip or Image."
  type        = string
  default     = "Zip"
}

variable "filename" {
  description = "Local zip file path."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket for zip deployment."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key for zip deployment."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for container Lambda."
  type        = string
  default     = null
}

variable "image_config" {
  description = "Container image overrides."
  type = object({
    command           = optional(list(string), [])
    entry_point       = optional(list(string), [])
    working_directory = optional(string, null)
  })
  default = null
}

# ── Runtime & Hardware ────────────────────────────────────────────────────────
variable "handler" {
  description = "Function handler."
  type        = string
  default     = "app.handler"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "architectures" {
  description = "x86_64 or arm64."
  type        = list(string)
  default     = ["x86_64"]
}

variable "memory_size" {
  description = "Memory in MB."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Timeout in seconds."
  type        = number
  default     = 30
}

variable "ephemeral_storage_size" {
  description = "/tmp size in MB."
  type        = number
  default     = 512
}

variable "publish" {
  description = "Publish new version on deploy."
  type        = bool
  default     = true
}

variable "layers" {
  description = "Layer ARNs to attach."
  type        = list(string)
  default     = []
}

variable "snap_start" {
  description = "SnapStart for Java. None or PublishedVersions."
  type        = string
  default     = "None"
}

# ── VPC ───────────────────────────────────────────────────────────────────────
variable "subnet_ids" {
  description = "Subnets for VPC Lambda. Empty = public Lambda."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups for VPC Lambda."
  type        = list(string)
  default     = []
}

# ── EFS ───────────────────────────────────────────────────────────────────────
variable "efs_access_point_arn" {
  description = "EFS access point ARN."
  type        = string
  default     = null
}

variable "efs_local_mount_path" {
  description = "EFS local mount path (e.g. /mnt/data)."
  type        = string
  default     = null
}

# ── Environment & Encryption ──────────────────────────────────────────────────
variable "environment_variables" {
  description = "Function environment variables."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key for environment variable encryption."
  type        = string
  default     = null
}

# ── Concurrency ───────────────────────────────────────────────────────────────
variable "reserved_concurrent_executions" {
  description = "Reserved concurrency. -1 = unreserved."
  type        = number
  default     = -1
}

variable "provisioned_concurrent_executions" {
  description = "Provisioned concurrency units. 0 = disabled."
  type        = number
  default     = 0
}

variable "provisioned_concurrency_alias" {
  description = "Alias to attach provisioned concurrency."
  type        = string
  default     = null
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for provisioned concurrency."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Auto-scaling minimum."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Auto-scaling maximum."
  type        = number
  default     = 10
}

variable "autoscaling_target_utilization" {
  description = "Auto-scaling target utilization %."
  type        = number
  default     = 70
}

variable "autoscaling_scale_in_cooldown" {
  description = "Scale-in cooldown seconds."
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Scale-out cooldown seconds."
  type        = number
  default     = 60
}

# ── Aliases ───────────────────────────────────────────────────────────────────
variable "aliases" {
  description = "Map of alias name → config."
  type = map(object({
    description        = optional(string, "")
    routing_weight     = optional(number, null)
    additional_version = optional(string, null)
  }))
  default = {}
}

# ── Tracing ───────────────────────────────────────────────────────────────────
variable "tracing_mode" {
  description = "X-Ray tracing: PassThrough or Active."
  type        = string
  default     = "PassThrough"
}

# ── Dead Letter & Async ───────────────────────────────────────────────────────
variable "dead_letter_target_arn" {
  description = "DLQ SQS/SNS ARN."
  type        = string
  default     = null
}

variable "async_on_success_destination_arn" {
  description = "Async success destination ARN."
  type        = string
  default     = null
}

variable "async_on_failure_destination_arn" {
  description = "Async failure destination ARN."
  type        = string
  default     = null
}

variable "async_maximum_event_age_in_seconds" {
  description = "Max async event age."
  type        = number
  default     = 21600
}

variable "async_maximum_retry_attempts" {
  description = "Max async retries."
  type        = number
  default     = 2
}

# ── Function URL ──────────────────────────────────────────────────────────────
variable "create_function_url" {
  description = "Create Lambda Function URL."
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "AWS_IAM or NONE."
  type        = string
  default     = "AWS_IAM"
}

variable "function_url_invoke_mode" {
  description = "BUFFERED or RESPONSE_STREAM."
  type        = string
  default     = "BUFFERED"
}

variable "function_url_cors" {
  description = "CORS config for Function URL."
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_origins     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 0)
  })
  default = null
}

# ── Triggers ─────────────────────────────────────────────────────────────────
variable "allowed_triggers" {
  description = "Resource-based policy triggers."
  type = map(object({
    principal      = string
    source_arn     = optional(string, null)
    source_account = optional(string, null)
    action         = optional(string, "lambda:InvokeFunction")
    qualifier      = optional(string, null)
  }))
  default = {}
}

# ── Event Source Mappings ─────────────────────────────────────────────────────
variable "event_source_mappings" {
  description = "SQS/DynamoDB/Kinesis event source mappings."
  type = map(object({
    event_source_arn                   = string
    batch_size                         = optional(number, 10)
    maximum_batching_window_in_seconds = optional(number, 0)
    starting_position                  = optional(string, null)
    starting_position_timestamp        = optional(string, null)
    enabled                            = optional(bool, true)
    bisect_batch_on_function_error     = optional(bool, false)
    maximum_retry_attempts             = optional(number, null)
    tumbling_window_in_seconds         = optional(number, null)
    parallelization_factor             = optional(number, null)
    function_response_types            = optional(list(string), [])
    filter_criteria = optional(list(object({
      pattern = string
    })), [])
    destination_config = optional(object({
      on_failure_destination_arn = optional(string, null)
    }), null)
  }))
  default = {}
}

# ── Schedules ────────────────────────────────────────────────────────────────
variable "schedules" {
  description = "EventBridge Scheduler schedules."
  type = map(object({
    schedule_expression                = string
    schedule_expression_timezone       = optional(string, "UTC")
    description                        = optional(string, "")
    state                              = optional(string, "ENABLED")
    input                              = optional(string, "{}")
    flexible_time_window_minutes       = optional(number, 0)
    retry_maximum_event_age_in_seconds = optional(number, null)
    retry_maximum_retry_attempts       = optional(number, null)
  }))
  default = {}
}

variable "scheduler_role_arn" {
  description = "IAM role for EventBridge Scheduler. Auto-created if null."
  type        = string
  default     = null
}

# ── Lambda Layers (create) ────────────────────────────────────────────────────
variable "lambda_layers" {
  description = "Lambda Layers to create."
  type = map(object({
    description              = optional(string, "")
    filename                 = optional(string, null)
    s3_bucket                = optional(string, null)
    s3_key                   = optional(string, null)
    s3_object_version        = optional(string, null)
    compatible_runtimes      = optional(list(string), [])
    compatible_architectures = optional(list(string), ["x86_64"])
    license_info             = optional(string, null)
    source_code_hash         = optional(string, null)
    retain_on_delete         = optional(bool, false)
  }))
  default = {}
}

# ── Code Signing ──────────────────────────────────────────────────────────────
variable "code_signing_config_arn" {
  description = "Existing Code Signing Config ARN."
  type        = string
  default     = null
}

variable "allowed_publishers_signing_profile_arns" {
  description = "Signing Profile ARNs for new Code Signing Config."
  type        = list(string)
  default     = []
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────
variable "log_retention_days" {
  description = "Log retention in days."
  type        = number
  default     = 30
}

variable "log_kms_key_id" {
  description = "KMS key for log encryption."
  type        = string
  default     = null
}

variable "log_format" {
  description = "Text or JSON."
  type        = string
  default     = "Text"
}

variable "application_log_level" {
  description = "App log level for JSON format."
  type        = string
  default     = "INFO"
}

variable "system_log_level" {
  description = "System log level for JSON format."
  type        = string
  default     = "WARN"
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
variable "create_cloudwatch_alarms" {
  description = "Create Lambda alarms."
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic for alarms."
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "SNS ARNs for alarm actions."
  type        = list(string)
  default     = []
}

variable "alarm_error_threshold" {
  description = "Error count for alarm."
  type        = number
  default     = 1
}

variable "alarm_throttle_threshold" {
  description = "Throttle count for alarm."
  type        = number
  default     = 5
}

variable "alarm_duration_threshold_ms" {
  description = "Duration ms for alarm. 0 = disabled."
  type        = number
  default     = 0
}

variable "alarm_evaluation_periods" {
  description = "Alarm evaluation periods."
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "Alarm metric period seconds."
  type        = number
  default     = 60
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
variable "create_cloudwatch_dashboard" {
  description = "Create CloudWatch dashboard."
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Dashboard name override."
  type        = string
  default     = null
}

# ── Lambda Insights ───────────────────────────────────────────────────────────
variable "enable_lambda_insights" {
  description = "Enable Lambda Insights layer."
  type        = bool
  default     = false
}

variable "lambda_insights_version" {
  description = "Lambda Insights layer version."
  type        = number
  default     = 21
}
