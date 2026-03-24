variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name used in resource tagging."
  type        = string
  default     = "data-platform"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "prod-"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms."
  type        = string
}

# S3 buckets (must be pre-created)
variable "data_lake_bucket_arn" {
  description = "ARN of the S3 data lake bucket for Firehose delivery."
  type        = string
}

variable "redshift_backup_bucket_arn" {
  description = "ARN of the S3 bucket used for Redshift Firehose backup."
  type        = string
}

# Redshift
variable "redshift_jdbc_url" {
  description = "JDBC URL for the Redshift cluster."
  type        = string
}

variable "redshift_username" {
  description = "Redshift user for Firehose delivery."
  type        = string
  default     = "firehose_loader"
}

variable "redshift_password" {
  description = "Redshift password for Firehose delivery."
  type        = string
  sensitive   = true
}

# Flink / Analytics
variable "flink_code_s3_bucket" {
  description = "S3 bucket that holds the Flink application JAR."
  type        = string
}

variable "flink_code_s3_key" {
  description = "S3 key of the Flink application JAR."
  type        = string
  default     = "flink-apps/clickstream-processor-1.0.jar"
}

variable "analytics_log_stream_arn" {
  description = "CloudWatch Logs stream ARN for Flink application logging."
  type        = string
  default     = null
}

# Lambda transformation
variable "lambda_processor_arn" {
  description = "ARN of the Lambda function used for Firehose data transformation."
  type        = string
  default     = null
}

# KMS
variable "kms_key_id" {
  description = "KMS key ID or alias for stream encryption."
  type        = string
  default     = "alias/aws/kinesis"
}

variable "s3_kms_key_arn" {
  description = "KMS key ARN for S3 Firehose SSE."
  type        = string
  default     = null
}
