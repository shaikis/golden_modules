variable "aws_region" {
  description = "Primary AWS region."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "prod"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms."
  type        = string
  default     = null
}

variable "backup_secondary_vault_arn" {
  description = "ARN of the backup vault in the secondary region."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for DynamoDB SSE (null uses AWS-owned key)."
  type        = string
  default     = null
}

variable "inventory_kinesis_stream_arn" {
  description = "Kinesis stream ARN for events table CDC."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "ecommerce"
  }
}
