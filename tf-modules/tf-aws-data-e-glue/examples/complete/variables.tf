variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project / cost-centre identifier."
  type        = string
  default     = "data-platform"
}

variable "data_lake_bucket_name" {
  description = "Name of the S3 data lake bucket."
  type        = string
}

variable "assets_bucket_name" {
  description = "Name of the S3 bucket that holds Glue scripts and assets."
  type        = string
}

variable "rds_jdbc_url" {
  description = "JDBC URL for the source RDS PostgreSQL instance."
  type        = string
}

variable "rds_username" {
  description = "RDS master username."
  type        = string
}

variable "rds_password" {
  description = "RDS master password (use Secrets Manager in production)."
  type        = string
  sensitive   = true
}

variable "rds_subnet_id" {
  description = "Subnet ID where the RDS instance resides."
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID that allows Glue → RDS traffic on 5432."
  type        = string
}

variable "rds_availability_zone" {
  description = "Availability zone of the RDS subnet."
  type        = string
  default     = "us-east-1a"
}

variable "msk_bootstrap_servers" {
  description = "MSK/Kafka bootstrap server string."
  type        = string
}

variable "msk_subnet_id" {
  description = "Subnet ID for the MSK cluster."
  type        = string
}

variable "msk_security_group_id" {
  description = "Security group ID that allows Glue → MSK traffic on 9092/9094."
  type        = string
}

variable "glue_kms_key_arn" {
  description = "KMS key ARN used for Glue security configuration encryption."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
