variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "subnet_id" {
  description = "Subnet ID for EMR cluster nodes."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for EMR Studio."
  type        = string
}

variable "studio_subnet_ids" {
  description = "Subnet IDs for EMR Studio."
  type        = list(string)
}

variable "workspace_security_group_id" {
  description = "Security group ID for EMR Studio workspace."
  type        = string
}

variable "engine_security_group_id" {
  description = "Security group ID for EMR Studio engine."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications."
  type        = string
  default     = null
}

variable "log_bucket" {
  description = "S3 bucket for EMR logs."
  type        = string
  default     = "my-emr-logs-bucket"
}

variable "studio_s3_bucket" {
  description = "S3 bucket for EMR Studio workspace storage."
  type        = string
  default     = "my-emr-studio-bucket"
}

variable "serverless_subnet_ids" {
  description = "Subnet IDs for EMR Serverless network configuration."
  type        = list(string)
  default     = []
}

variable "serverless_security_group_ids" {
  description = "Security group IDs for EMR Serverless network configuration."
  type        = list(string)
  default     = []
}
