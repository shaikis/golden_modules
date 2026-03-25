variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for MSK encryption at rest."
  type        = string
  default     = null
}
