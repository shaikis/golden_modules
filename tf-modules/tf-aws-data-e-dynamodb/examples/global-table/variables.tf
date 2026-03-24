variable "primary_region" {
  description = "Primary AWS region for Global Table management."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "prod"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for replication latency alarms."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    Environment = "production"
    Team        = "platform"
    Global      = "true"
  }
}
