variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for SageMaker domain."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for SageMaker domain and model VPC config."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms."
  type        = string
  default     = null
}

variable "data_bucket_arns" {
  description = "S3 bucket ARNs for training data and model artifacts."
  type        = list(string)
  default     = []
}

variable "offline_feature_store_bucket" {
  description = "S3 bucket name for Feature Store offline storage."
  type        = string
}
