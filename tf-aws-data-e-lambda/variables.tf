# ── Naming & Tagging ──────────────────────────────────────────────────────────
variable "function_name" {
  description = "Base name for the Lambda function."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to all resource names: <prefix>-<function_name>."
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner team or individual for tagging."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center code for tagging."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

# ── IAM Execution Role ────────────────────────────────────────────────────────
# BYO pattern:
#   create_role = true  + role_arn = null  → module creates a new role  (default)
#   create_role = false + role_arn = "arn" → use the existing role (no new role created)
variable "create_role" {
  description = <<-EOT
    When true (default) the module creates an IAM execution role automatically.
    Set to false and provide role_arn to bring your own existing role.
  EOT
  type        = bool
  default     = true
}

variable "role_arn" {
  description = <<-EOT
    ARN of an existing IAM execution role.
    When provided, create_role is ignored and no new role is created.
    When null (default) and create_role = true, the module creates a new role.
  EOT
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = <<-EOT
    List of managed policy ARNs to attach to the auto-created execution role.
    AWSLambdaBasicExecutionRole is always appended automatically.
    VPC and X-Ray policies are auto-added based on subnet_ids and tracing_mode.
  EOT
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

variable "inline_policies" {
  description = "Map of inline policy name → JSON policy document attached to the auto-created role."
  type        = map(string)
  default     = {}
}

# ── Package & Code Source ─────────────────────────────────────────────────────
variable "package_type" {
  description = "Lambda deployment package type. Zip = code archive. Image = ECR container image."
  type        = string
  default     = "Zip"
  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be 'Zip' or 'Image'."
  }
}

variable "filename" {
  description = "Path to a local .zip deployment package. Triggers redeployment when the file changes."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "base64-encoded SHA256 of the zip file. Use filebase64sha256(var.filename) to trigger updates."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment zip. Use with s3_key."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 object key of the deployment zip."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version of the deployment zip."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for container image Lambdas. Only used when package_type = Image."
  type        = string
  default     = null
}

variable "image_config" {
  description = <<-EOT
    Container image override configuration. Only used when package_type = Image.
      command           - Overrides CMD
      entry_point       - Overrides ENTRYPOINT
      working_directory - Overrides working directory
  EOT
  type = object({
    command           = optional(list(string), [])
    entry_point       = optional(list(string), [])
    working_directory = optional(string, null)
  })
  default = null
}

# ── Runtime & Hardware ────────────────────────────────────────────────────────
variable "handler" {
  description = "Function handler entrypoint (e.g. index.handler). Not used for Image deployments."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime (e.g. python3.12, nodejs20.x, java21). Not used for Image deployments."
  type        = string
  default     = "python3.12"
}

variable "architectures" {
  description = "Instruction set architecture list. x86_64 or arm64 (Graviton — cheaper + faster)."
  type        = list(string)
  default     = ["x86_64"]
  validation {
    condition     = alltrue([for a in var.architectures : contains(["x86_64", "arm64"], a)])
    error_message = "Each architecture must be x86_64 or arm64."
  }
}

variable "memory_size" {
  description = "Memory allocated to the function in MB (128–10240). Also controls proportional CPU."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Maximum execution time in seconds (1–900)."
  type        = number
  default     = 30
}

variable "ephemeral_storage_size" {
  description = "Size of /tmp ephemeral storage in MB (512–10240)."
  type        = number
  default     = 512
}

variable "publish" {
  description = "Publish a new immutable version on every deployment. Required for aliases and provisioned concurrency."
  type        = bool
  default     = true
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach (max 5, including Lambda Insights if enabled)."
  type        = list(string)
  default     = []
}

# ── SnapStart (Java) ──────────────────────────────────────────────────────────
variable "snap_start" {
  description = "Enable SnapStart for Java 11+ runtimes. PublishedVersions enables it; None disables."
  type        = string
  default     = "None"
  validation {
    condition     = contains(["None", "PublishedVersions"], var.snap_start)
    error_message = "snap_start must be 'None' or 'PublishedVersions'."
  }
}

# ── VPC Configuration ─────────────────────────────────────────────────────────
variable "subnet_ids" {
  description = <<-EOT
    Subnet IDs for VPC-attached Lambda.
    Empty list (default) = public Lambda with internet access.
    Non-empty list       = VPC Lambda; AWSLambdaVPCAccessExecutionRole is auto-attached.
  EOT
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for VPC-attached Lambda. Required when subnet_ids is set."
  type        = list(string)
  default     = []
}

# ── EFS Mount ─────────────────────────────────────────────────────────────────
variable "efs_access_point_arn" {
  description = "EFS Access Point ARN to mount inside the Lambda. Requires subnet_ids to be set."
  type        = string
  default     = null
}

variable "efs_local_mount_path" {
  description = "Path inside the Lambda container where EFS is mounted (e.g. /mnt/data)."
  type        = string
  default     = null
}

# ── Environment Variables & Encryption ───────────────────────────────────────
variable "environment_variables" {
  description = "Key-value map of environment variables passed to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt environment variables and the deployment package at rest."
  type        = string
  default     = null
}

# ── Concurrency ───────────────────────────────────────────────────────────────
variable "reserved_concurrent_executions" {
  description = "Reserved concurrency limit. -1 = unreserved (default). 0 = throttle all invocations."
  type        = number
  default     = -1
}

variable "provisioned_concurrent_executions" {
  description = "Number of pre-initialised execution environments. 0 = disabled. Requires publish = true and at least one alias."
  type        = number
  default     = 0
}

variable "provisioned_concurrency_alias" {
  description = "Alias name to attach provisioned concurrency to. Defaults to the first alias key."
  type        = string
  default     = null
}

# ── Provisioned Concurrency Auto-Scaling ──────────────────────────────────────
variable "enable_autoscaling" {
  description = "Enable Application Auto Scaling for provisioned concurrency. Requires provisioned_concurrent_executions > 0."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum provisioned concurrency when auto-scaling."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum provisioned concurrency when auto-scaling."
  type        = number
  default     = 10
}

variable "autoscaling_target_utilization" {
  description = "Target utilization percentage (0–100) for provisioned concurrency scaling."
  type        = number
  default     = 70
}

variable "autoscaling_scale_in_cooldown" {
  description = "Scale-in cooldown period in seconds."
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Scale-out cooldown period in seconds."
  type        = number
  default     = 60
}

# ── Aliases ───────────────────────────────────────────────────────────────────
variable "aliases" {
  description = <<-EOT
    Map of alias name → configuration.
    routing_weight + additional_version enable weighted alias routing (canary deploys).
    Example:
      aliases = {
        live   = { description = "Production" }
        canary = { description = "Canary 10%", routing_weight = 0.1, additional_version = "5" }
      }
  EOT
  type = map(object({
    description        = optional(string, "")
    routing_weight     = optional(number, null)
    additional_version = optional(string, null)
  }))
  default = {}
}

# ── X-Ray Tracing ─────────────────────────────────────────────────────────────
variable "tracing_mode" {
  description = "X-Ray tracing mode. Active = trace all requests. PassThrough = no tracing."
  type        = string
  default     = "PassThrough"
  validation {
    condition     = contains(["PassThrough", "Active"], var.tracing_mode)
    error_message = "tracing_mode must be PassThrough or Active."
  }
}

# ── Dead Letter & Async Destinations ─────────────────────────────────────────
variable "dead_letter_target_arn" {
  description = "SQS queue or SNS topic ARN for failed synchronous invocations (dead letter config)."
  type        = string
  default     = null
}

variable "async_on_success_destination_arn" {
  description = "ARN (SQS / SNS / Lambda / EventBridge) invoked on successful async execution."
  type        = string
  default     = null
}

variable "async_on_failure_destination_arn" {
  description = "ARN (SQS / SNS / Lambda / EventBridge) invoked on failed async execution."
  type        = string
  default     = null
}

variable "async_maximum_event_age_in_seconds" {
  description = "Maximum age of an async event before Lambda discards it (60–21600)."
  type        = number
  default     = 21600
}

variable "async_maximum_retry_attempts" {
  description = "Maximum async retry attempts (0–2)."
  type        = number
  default     = 2
}

# ── Function URL ──────────────────────────────────────────────────────────────
variable "create_function_url" {
  description = "Create a Lambda Function URL — HTTPS endpoint without needing API Gateway."
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Auth for Function URL. AWS_IAM = requires SigV4. NONE = public endpoint."
  type        = string
  default     = "AWS_IAM"
  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "function_url_auth_type must be AWS_IAM or NONE."
  }
}

variable "function_url_invoke_mode" {
  description = "Invocation mode. BUFFERED = standard response. RESPONSE_STREAM = streaming."
  type        = string
  default     = "BUFFERED"
  validation {
    condition     = contains(["BUFFERED", "RESPONSE_STREAM"], var.function_url_invoke_mode)
    error_message = "function_url_invoke_mode must be BUFFERED or RESPONSE_STREAM."
  }
}

variable "function_url_cors" {
  description = "CORS configuration for the Function URL. Only applied when create_function_url = true."
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

# ── Triggers / Resource-based Permissions ─────────────────────────────────────
variable "allowed_triggers" {
  description = <<-EOT
    Map of Lambda resource-based policy statements allowing services to invoke the function.
    Key = statement ID suffix.
    Examples:
      apigw    = { principal = "apigateway.amazonaws.com", source_arn = "arn:aws:execute-api:..." }
      s3_event = { principal = "s3.amazonaws.com",         source_arn = "arn:aws:s3:::my-bucket" }
      sns_sub  = { principal = "sns.amazonaws.com",        source_arn = "arn:aws:sns:..." }
  EOT
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
  description = <<-EOT
    Map of event source mapping configurations (SQS, DynamoDB Streams, Kinesis, MSK, MQ).
    Key = logical name.
  EOT
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

# ── EventBridge Scheduler ─────────────────────────────────────────────────────
variable "schedules" {
  description = <<-EOT
    Map of EventBridge Scheduler schedules to trigger this Lambda.
    A dedicated scheduler IAM role is auto-created when schedules are defined and scheduler_role_arn is null.
    Example:
      schedules = {
        nightly = {
          schedule_expression = "cron(0 2 * * ? *)"
          description         = "Nightly cleanup"
          input               = jsonencode({ action = "cleanup" })
        }
      }
  EOT
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
  description = "IAM role ARN for EventBridge Scheduler to invoke Lambda. Auto-created when null and schedules are defined."
  type        = string
  default     = null
}

# ── Lambda Layers — create new ────────────────────────────────────────────────
variable "lambda_layers" {
  description = <<-EOT
    Map of Lambda Layer definitions to create inside this module.
    Created layer ARNs are automatically appended to the function's layer list.
    Key = logical name.
  EOT
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
  description = "ARN of an existing Code Signing Config to associate with this function."
  type        = string
  default     = null
}

variable "allowed_publishers_signing_profile_arns" {
  description = "Signing Profile ARNs allowed to sign this function. Triggers creation of a new Code Signing Config."
  type        = list(string)
  default     = []
}

variable "signing_untrusted_artifact_on_deployment" {
  description = "Action on untrusted artifact at deploy time. Warn or Enforce."
  type        = string
  default     = "Warn"
  validation {
    condition     = contains(["Warn", "Enforce"], var.signing_untrusted_artifact_on_deployment)
    error_message = "Must be Warn or Enforce."
  }
}

# ── CloudWatch Logs ───────────────────────────────────────────────────────────
variable "log_retention_days" {
  description = "Days to retain Lambda CloudWatch logs. 0 = never expire."
  type        = number
  default     = 30
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention period."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ARN for CloudWatch Log Group encryption."
  type        = string
  default     = null
}

variable "log_format" {
  description = "Lambda log format. Text = plain text. JSON = structured logging with level filtering."
  type        = string
  default     = "Text"
  validation {
    condition     = contains(["Text", "JSON"], var.log_format)
    error_message = "log_format must be Text or JSON."
  }
}

variable "application_log_level" {
  description = "Application log level when log_format = JSON. TRACE | DEBUG | INFO | WARN | ERROR | FATAL."
  type        = string
  default     = "INFO"
}

variable "system_log_level" {
  description = "Lambda system log level when log_format = JSON. DEBUG | INFO | WARN."
  type        = string
  default     = "WARN"
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for Lambda errors, throttles, duration, and concurrency."
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "List of SNS topic ARNs for alarm actions. Takes precedence over alarm_sns_topic_arn."
  type        = list(string)
  default     = []
}

variable "alarm_error_threshold" {
  description = "Number of Lambda errors that trigger the errors alarm."
  type        = number
  default     = 1
}

variable "alarm_throttle_threshold" {
  description = "Number of throttles that trigger the throttles alarm."
  type        = number
  default     = 5
}

variable "alarm_duration_threshold_ms" {
  description = "Average duration (ms) that triggers the duration alarm. 0 = alarm disabled."
  type        = number
  default     = 0
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms."
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "Alarm metric evaluation period in seconds."
  type        = number
  default     = 60
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
variable "create_cloudwatch_dashboard" {
  description = "Create a CloudWatch dashboard with Lambda invocation, error, duration, and concurrency metrics."
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Override the dashboard name. Defaults to <name>-lambda-dashboard."
  type        = string
  default     = null
}

# ── Lambda Insights ───────────────────────────────────────────────────────────
variable "enable_lambda_insights" {
  description = "Enable Lambda Insights enhanced monitoring via the CloudWatch Lambda Insights extension layer."
  type        = bool
  default     = false
}

variable "lambda_insights_version" {
  description = "Lambda Insights extension version to use. See AWS docs for latest."
  type        = number
  default     = 21

}
