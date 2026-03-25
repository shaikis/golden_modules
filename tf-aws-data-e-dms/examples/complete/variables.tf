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
  description = "KMS key ARN for DMS replication instance encryption."
  type        = string
  default     = null
}

variable "dms_s3_service_role_arn" {
  description = "IAM role ARN for DMS S3 endpoint access (service_access_role_arn)."
  type        = string
  default     = null
}

variable "oracle_server_name" {
  description = "Hostname of the Oracle source database."
  type        = string
  default     = "oracle.internal.example.com"
}

variable "pg_server_name" {
  description = "Hostname of the PostgreSQL source database."
  type        = string
  default     = "rds-pg.internal.example.com"
}

variable "mysql_server_name" {
  description = "Hostname of the MySQL source database."
  type        = string
  default     = "rds-mysql.internal.example.com"
}

variable "aurora_server_name" {
  description = "Hostname of the Aurora target database."
  type        = string
  default     = "aurora-mysql.cluster.example.com"
}

variable "redshift_server_name" {
  description = "Hostname of the Redshift target cluster."
  type        = string
  default     = "redshift.example.com"
}

variable "s3_landing_bucket" {
  description = "S3 bucket name for the data lake landing zone (DMS target)."
  type        = string
  default     = "my-data-lake-landing"
}
