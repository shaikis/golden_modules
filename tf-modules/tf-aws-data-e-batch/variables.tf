variable "create_scheduling_policies" {
  description = "Whether to create Batch fair-share scheduling policies."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for AWS Batch queues."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Whether to create IAM roles for AWS Batch (service role, EC2 instance role, ECS task execution role, job role, Spot fleet role)."
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic to send CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "role_arn" {
  description = "ARN of an existing IAM service role for AWS Batch. Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "tags" {
  description = "Default tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "compute_environments" {
  description = "Map of AWS Batch compute environment configurations."
  type = map(object({
    type                    = optional(string, "MANAGED")
    compute_type            = optional(string, "FARGATE_SPOT")
    max_vcpus               = optional(number, 256)
    min_vcpus               = optional(number, 0)
    desired_vcpus           = optional(number, 0)
    instance_types          = optional(list(string), ["optimal"])
    subnet_ids              = optional(list(string), [])
    security_group_ids      = optional(list(string), [])
    spot_bid_percentage     = optional(number, 60)
    allocation_strategy     = optional(string, "SPOT_PRICE_CAPACITY_OPTIMIZED")
    ec2_key_pair            = optional(string, null)
    placement_group         = optional(string, null)
    launch_template_id      = optional(string, null)
    launch_template_version = optional(string, null)
    eks_cluster_arn         = optional(string, null)
    kubernetes_namespace    = optional(string, null)
    terminate_on_update     = optional(bool, false)
    update_timeout_minutes  = optional(number, 30)
    state                   = optional(string, "ENABLED")
    instance_tags           = optional(map(string), {})
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "job_queues" {
  description = "Map of AWS Batch job queue configurations."
  type = map(object({
    priority                   = optional(number, 10)
    state                      = optional(string, "ENABLED")
    compute_environment_keys   = list(string)
    compute_environment_orders = optional(list(number), null)
    scheduling_policy_key      = optional(string, null)
    job_state_time_limit_actions = optional(list(object({
      action           = string
      max_time_seconds = number
      reason           = string
      state            = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "job_definitions" {
  description = "Map of AWS Batch job definition configurations."
  type = map(object({
    type                          = optional(string, "container")
    platform_capabilities         = optional(list(string), ["FARGATE"])
    image                         = string
    vcpus                         = optional(number, 1)
    memory                        = optional(number, 2048)
    command                       = optional(list(string), [])
    environment                   = optional(map(string), {})
    job_role_arn                  = optional(string, null)
    execution_role_arn            = optional(string, null)
    retry_attempts                = optional(number, 1)
    timeout_seconds               = optional(number, 3600)
    propagate_tags                = optional(bool, true)
    assign_public_ip              = optional(string, "DISABLED")
    gpu_count                     = optional(number, 0)
    scheduling_priority           = optional(number, null)
    container_properties_override = optional(string, null)
    tags                          = optional(map(string), {})
  }))
  default = {}
}

variable "scheduling_policies" {
  description = "Map of AWS Batch fair-share scheduling policy configurations."
  type = map(object({
    compute_reservation = optional(number, 0)
    share_decay_seconds = optional(number, 3600)
    share_distributions = optional(list(object({
      share_identifier = string
      weight_factor    = number
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "alarm_thresholds" {
  description = "Thresholds for CloudWatch alarms."
  type = object({
    pending_job_count_max = optional(number, 100)
    failed_job_count_max  = optional(number, 10)
  })
  default = {}
}
