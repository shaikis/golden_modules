variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "subnet_ids" {
  description = "Subnet IDs for Batch compute environments."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for Batch compute environments."
  type        = list(string)
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "ecr_account_id" {
  description = "AWS account ID hosting ECR images."
  type        = string
  default     = "123456789012"
}
