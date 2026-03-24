variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = ""
}
variable "owner" {
  type    = string
  default = ""
}
variable "cost_center" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}

# ===========================================================================
# OS & AMI
# ===========================================================================
variable "os_type" {
  description = "linux or windows — drives userdata template and AMI lookup."
  type        = string
  default     = "linux"
  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type must be 'linux' or 'windows'."
  }
}

variable "ami_id" {
  description = "Override AMI. If null, latest Amazon Linux 2023 or Windows Server 2022 is used."
  type        = string
  default     = null
}

variable "windows_ami_pattern" {
  description = "SSM parameter path for Windows AMI (used when ami_id is null and os_type = windows)."
  type        = string
  default     = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

# ===========================================================================
# LAUNCH TEMPLATE
# ===========================================================================
variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name. Leave null for SSM-only access."
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile. Required for SSM access and hostname tagging."
  type        = string
  default     = null
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "associate_public_ip" {
  type    = bool
  default = false
}

variable "ebs_optimized" {
  type    = bool
  default = true
}

variable "enable_detailed_monitoring" {
  type    = bool
  default = true
}

variable "kms_key_arn" {
  description = "KMS key for root and data volumes."
  type        = string
  default     = null
}

variable "root_volume_size" {
  type    = number
  default = 50
}

variable "root_volume_type" {
  type    = string
  default = "gp3"
}

variable "root_volume_iops" {
  type    = number
  default = null
}

variable "root_volume_throughput" {
  type    = number
  default = null
}

variable "extra_ebs_volumes" {
  description = "Additional EBS volumes to attach at launch."
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = optional(string, "gp3")
    iops        = optional(number, null)
    throughput  = optional(number, null)
    encrypted   = optional(bool, true)
  }))
  default = []
}

variable "metadata_http_put_response_hop_limit" {
  description = "IMDSv2 hop limit. Use 1 for non-containerized, 2 for containers."
  type        = number
  default     = 1
}

# ===========================================================================
# USER DATA
# ===========================================================================
variable "user_data" {
  description = "Base64-encoded user_data. Overrides the built-in hostname template."
  type        = string
  default     = ""
}

variable "extra_user_data_commands" {
  description = "Extra shell/PS1 commands appended to the built-in userdata template."
  type        = string
  default     = ""
}

# ===========================================================================
# WINDOWS DOMAIN JOIN
# ===========================================================================
variable "windows_domain_name" {
  description = "Active Directory domain to join (Windows only)."
  type        = string
  default     = ""
}

variable "windows_domain_join_secret_arn" {
  description = "Secrets Manager ARN containing domain join credentials {username, password}."
  type        = string
  default     = ""
}

# ===========================================================================
# AUTO SCALING GROUP
# ===========================================================================
variable "vpc_zone_identifier" {
  description = "Subnet IDs for the ASG."
  type        = list(string)
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "health_check_type" {
  description = "EC2 or ELB."
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  type    = number
  default = 300
}

variable "default_cooldown" {
  type    = number
  default = 300
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

variable "termination_policies" {
  type    = list(string)
  default = ["OldestLaunchTemplate", "OldestInstance"]
}

variable "protect_from_scale_in" {
  type    = bool
  default = false
}

variable "capacity_rebalance" {
  type    = bool
  default = false
}

variable "instance_refresh_strategy" {
  description = "Rolling update strategy: Rolling or null to disable."
  type        = string
  default     = "Rolling"
}

variable "instance_refresh_min_healthy_percentage" {
  type    = number
  default = 90
}

variable "instance_refresh_checkpoint_percentages" {
  type    = list(number)
  default = [20, 50, 100]
}

# ===========================================================================
# MIXED INSTANCES / SPOT
# ===========================================================================
variable "use_mixed_instances_policy" {
  type    = bool
  default = false
}

variable "on_demand_base_capacity" {
  type    = number
  default = 1
}

variable "on_demand_percentage_above_base" {
  type    = number
  default = 0
}

variable "spot_allocation_strategy" {
  type    = string
  default = "price-capacity-optimized"
}

variable "override_instance_types" {
  description = "Instance types for mixed policy."
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t3.large"]
}

# ===========================================================================
# SCALING POLICIES
# ===========================================================================
variable "enable_cpu_scaling" {
  type    = bool
  default = true
}

variable "cpu_target_value" {
  type    = number
  default = 70
}

variable "enable_memory_scaling" {
  description = "Requires CloudWatch agent publishing MemoryUtilization metric."
  type        = bool
  default     = false
}

variable "memory_target_value" {
  type    = number
  default = 75
}

variable "scale_out_cooldown" {
  type    = number
  default = 60
}

variable "scale_in_cooldown" {
  type    = number
  default = 300
}

# ALB request count per target scaling
variable "enable_alb_request_scaling" {
  type    = bool
  default = false
}

variable "alb_request_target_value" {
  description = "Target requests per target per minute."
  type        = number
  default     = 1000
}

variable "alb_target_group_arn_suffix" {
  description = "ALB target group ARN suffix (from aws_lb_target_group.this.arn_suffix)."
  type        = string
  default     = null
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (from aws_lb.this.arn_suffix)."
  type        = string
  default     = null
}

# SQS queue depth scaling
variable "enable_sqs_scaling" {
  type    = bool
  default = false
}

variable "sqs_queue_name" {
  description = "SQS queue name to track visible message count."
  type        = string
  default     = null
}

variable "sqs_messages_per_instance" {
  description = "Target number of visible messages per EC2 instance."
  type        = number
  default     = 100
}

# Network IN/OUT scaling
variable "enable_network_in_scaling" {
  type    = bool
  default = false
}

variable "network_in_target_bytes" {
  description = "Target network bytes in per instance per minute."
  type        = number
  default     = 10000000 # 10 MB/min
}

variable "enable_network_out_scaling" {
  type    = bool
  default = false
}

variable "network_out_target_bytes" {
  type    = number
  default = 10000000
}

# Step scaling (custom step policies)
variable "step_scaling_policies" {
  description = "Custom step scaling policies."
  type = map(object({
    adjustment_type         = string # ChangeInCapacity | ExactCapacity | PercentChangeInCapacity
    metric_aggregation_type = optional(string, "Average")
    cooldown                = optional(number, 300)
    step_adjustments = list(object({
      lower_bound        = optional(number, null)
      upper_bound        = optional(number, null)
      scaling_adjustment = number
    }))
    # CloudWatch alarm to trigger this policy
    alarm_metric_name         = string
    alarm_namespace           = optional(string, "AWS/EC2")
    alarm_statistic           = optional(string, "Average")
    alarm_period              = optional(number, 60)
    alarm_evaluation_periods  = optional(number, 2)
    alarm_threshold           = number
    alarm_comparison_operator = string # GreaterThanThreshold | LessThanThreshold | etc.
    alarm_dimensions          = optional(map(string), {})
  }))
  default = {}
}

# ===========================================================================
# SCALE-IN PROTECTION (instance level)
# ===========================================================================
variable "new_instances_protected_from_scale_in" {
  description = "Protect newly launched instances from scale-in immediately."
  type        = bool
  default     = false
}

variable "suspended_processes" {
  description = "ASG processes to suspend (e.g. ['Launch', 'Terminate', 'HealthCheck'])."
  type        = list(string)
  default     = []
}

variable "warm_pool" {
  description = "Configure a warm pool to reduce scale-out latency."
  type = object({
    pool_state                  = optional(string, "Stopped") # Stopped | Running | Hibernated
    min_size                    = optional(number, 0)
    max_group_prepared_capacity = optional(number, null)
    reuse_on_scale_in           = optional(bool, false)
  })
  default = null
}

# ===========================================================================
# SCHEDULED SCALING
# ===========================================================================
variable "scheduled_actions" {
  description = "Map of scheduled scaling actions."
  type = map(object({
    recurrence       = optional(string, null)
    start_time       = optional(string, null)
    end_time         = optional(string, null)
    min_size         = optional(number, null)
    max_size         = optional(number, null)
    desired_capacity = optional(number, null)
    time_zone        = optional(string, "UTC")
  }))
  default = {}
}

# ===========================================================================
# LIFECYCLE HOOKS
# ===========================================================================
variable "lifecycle_hooks" {
  description = "Lifecycle hooks for launching or terminating instances."
  type = map(object({
    lifecycle_transition    = string # autoscaling:EC2_INSTANCE_LAUNCHING | TERMINATING
    heartbeat_timeout       = optional(number, 300)
    default_result          = optional(string, "ABANDON")
    notification_target_arn = optional(string, null)
    role_arn                = optional(string, null)
  }))
  default = {}
}
