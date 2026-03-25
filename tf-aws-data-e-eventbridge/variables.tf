variable "create_custom_buses" {
  description = "Whether to create custom event buses."
  type        = bool
  default     = false
}

variable "create_api_connections" {
  description = "Whether to create EventBridge API connections."
  type        = bool
  default     = false
}

variable "create_api_destinations" {
  description = "Whether to create EventBridge API destinations."
  type        = bool
  default     = false
}

variable "create_archives" {
  description = "Whether to create event archives for replay."
  type        = bool
  default     = false
}

variable "create_pipes" {
  description = "Whether to create EventBridge Pipes."
  type        = bool
  default     = false
}

variable "create_schema_registries" {
  description = "Whether to create EventBridge schema registries and schemas."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for EventBridge rules."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Whether to create an IAM role for EventBridge to invoke targets."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Existing IAM role ARN to use for EventBridge invocations (from tf-aws-iam). Ignored when create_iam_role = true."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting event buses (from tf-aws-kms)."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name for the EventBridge invocation IAM role."
  type        = string
  default     = "eventbridge-invocation-role"
}

variable "iam_role_path" {
  description = "IAM path for the EventBridge invocation role."
  type        = string
  default     = "/"
}

variable "pipes_role_name" {
  description = "Name for the EventBridge Pipes IAM role."
  type        = string
  default     = "eventbridge-pipes-role"
}

# ── Target type gates ─────────────────────────────────────────────────────────
variable "enable_lambda_target" {
  description = "Grant Lambda invoke permissions to the EventBridge role."
  type        = bool
  default     = true
}

variable "enable_sqs_target" {
  description = "Grant SQS send-message permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_sns_target" {
  description = "Grant SNS publish permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_kinesis_target" {
  description = "Grant Kinesis put-record and Firehose put-record permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_stepfunctions_target" {
  description = "Grant Step Functions start-execution permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_ecs_target" {
  description = "Grant ECS run-task permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_batch_target" {
  description = "Grant Batch submit-job permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_sagemaker_target" {
  description = "Grant SageMaker pipeline start-execution permissions to the EventBridge role."
  type        = bool
  default     = false
}

variable "enable_api_destination_target" {
  description = "Grant API destination invoke permissions to the EventBridge role."
  type        = bool
  default     = false
}

# ── Custom event buses ────────────────────────────────────────────────────────
variable "event_buses" {
  description = "Map of custom event buses to create."
  type = map(object({
    event_source_name  = optional(string, null)
    kms_key_identifier = optional(string, null)
    tags               = optional(map(string), {})
  }))
  default = {}
}

# ── Event rules ───────────────────────────────────────────────────────────────
variable "rules" {
  description = "Map of EventBridge rules (scheduled or pattern-based)."
  type = map(object({
    description         = optional(string, null)
    event_bus_key       = optional(string, null)
    event_pattern       = optional(string, null)
    schedule_expression = optional(string, null)
    state               = optional(string, "ENABLED")
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ── Event targets ─────────────────────────────────────────────────────────────
variable "targets" {
  description = "Map of EventBridge rule targets."
  type = map(object({
    rule_key  = string
    target_id = optional(string, null)
    arn       = string
    role_arn  = optional(string, null)

    input      = optional(string, null)
    input_path = optional(string, null)

    input_transformer = optional(object({
      input_paths    = optional(map(string), {})
      input_template = string
    }), null)

    sqs_message_group_id  = optional(string, null)
    kinesis_partition_key = optional(string, null)
    sfn_input             = optional(string, null)

    retry_attempts        = optional(number, 185)
    max_event_age_seconds = optional(number, 86400)
    dead_letter_queue_arn = optional(string, null)

    ecs_target = optional(object({
      task_definition_arn = string
      cluster_arn         = string
      launch_type         = optional(string, "FARGATE")
      task_count          = optional(number, 1)
      subnet_ids          = optional(list(string), [])
      security_group_ids  = optional(list(string), [])
      assign_public_ip    = optional(bool, false)
      container_overrides = optional(list(object({
        name        = string
        command     = optional(list(string), [])
        environment = optional(map(string), {})
      })), [])
    }), null)
  }))
  default = {}
}

# ── API connections ───────────────────────────────────────────────────────────
variable "api_connections" {
  description = "Map of EventBridge API connections for HTTP destinations."
  type = map(object({
    description        = optional(string, null)
    authorization_type = string

    # API_KEY auth
    api_key_name  = optional(string, null)
    api_key_value = optional(string, null)

    # BASIC auth
    basic_username = optional(string, null)
    basic_password = optional(string, null)

    # OAUTH_CLIENT_CREDENTIALS auth
    oauth_client_id              = optional(string, null)
    oauth_client_secret          = optional(string, null)
    oauth_authorization_endpoint = optional(string, null)
    oauth_http_method            = optional(string, "POST")
    oauth_scope                  = optional(string, null)
  }))
  default = {}
}

# ── API destinations ──────────────────────────────────────────────────────────
variable "api_destinations" {
  description = "Map of EventBridge API destinations (HTTP endpoints)."
  type = map(object({
    connection_key                   = string
    invocation_endpoint              = string
    http_method                      = string
    description                      = optional(string, null)
    invocation_rate_limit_per_second = optional(number, 300)
  }))
  default = {}
}

# ── Archives ──────────────────────────────────────────────────────────────────
variable "archives" {
  description = "Map of EventBridge archives for event replay."
  type = map(object({
    event_source_arn = string
    description      = optional(string, null)
    retention_days   = optional(number, 0)
    event_pattern    = optional(string, null)
  }))
  default = {}
}

# ── Pipes ─────────────────────────────────────────────────────────────────────
variable "pipes" {
  description = "Map of EventBridge Pipes (source → filter → enrich → target)."
  type = map(object({
    description = optional(string, null)
    role_arn    = optional(string, null)

    source = string

    source_parameters = optional(object({
      filter_criteria = optional(object({
        filters = optional(list(object({
          pattern = string
        })), [])
      }), null)

      dynamodb_stream_parameters = optional(object({
        starting_position                  = optional(string, "TRIM_HORIZON")
        batch_size                         = optional(number, 1)
        maximum_batching_window_in_seconds = optional(number, 0)
        maximum_retry_attempts             = optional(number, -1)
      }), null)

      kinesis_stream_parameters = optional(object({
        starting_position                  = optional(string, "TRIM_HORIZON")
        batch_size                         = optional(number, 1)
        maximum_batching_window_in_seconds = optional(number, 0)
      }), null)

      sqs_queue_parameters = optional(object({
        batch_size                         = optional(number, 10)
        maximum_batching_window_in_seconds = optional(number, 0)
      }), null)
    }), null)

    enrichment                = optional(string, null)
    enrichment_input_template = optional(string, null)

    target = string

    target_parameters = optional(object({
      input_template = optional(string, null)
      sqs_queue_parameters = optional(object({
        message_group_id = optional(string, null)
      }), null)
      lambda_function_parameters = optional(object({
        invocation_type = optional(string, "FIRE_AND_FORGET")
      }), null)
      step_function_state_machine_parameters = optional(object({
        invocation_type = optional(string, "FIRE_AND_FORGET")
      }), null)
    }), null)

    desired_state = optional(string, "RUNNING")
    tags          = optional(map(string), {})
  }))
  default = {}
}

# ── Schema registries ─────────────────────────────────────────────────────────
variable "schema_registries" {
  description = "Map of EventBridge schema registries."
  type = map(object({
    description = optional(string, null)
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "schemas" {
  description = "Map of EventBridge schemas."
  type = map(object({
    registry_key = string
    type         = string
    content      = string
    description  = optional(string, null)
    tags         = optional(map(string), {})
  }))
  default = {}
}

variable "schema_discoverers" {
  description = "Map of EventBridge schema discoverers (auto-discover schemas from event buses)."
  type = map(object({
    event_bus_key = optional(string, null)
    description   = optional(string, null)
    tags          = optional(map(string), {})
  }))
  default = {}
}

# ── Alarm thresholds ──────────────────────────────────────────────────────────
variable "alarm_failed_invocations_threshold" {
  description = "Threshold for FailedInvocations alarm."
  type        = number
  default     = 0
}

variable "alarm_throttled_rules_threshold" {
  description = "Threshold for ThrottledRules alarm."
  type        = number
  default     = 0
}

variable "alarm_dead_letter_threshold" {
  description = "Threshold for DeadLetterInvocations alarm."
  type        = number
  default     = 0
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for alarms."
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "Alarm evaluation period in seconds."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}
