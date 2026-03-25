variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "prod-"
}

variable "kms_key_arn" {
  description = "KMS key ARN for MWAA environment encryption."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "prod_source_bucket_arn" {
  description = "S3 bucket ARN containing production DAGs, requirements, and plugins."
  type        = string
}

variable "dev_source_bucket_arn" {
  description = "S3 bucket ARN containing development DAGs, requirements, and plugins."
  type        = string
}

variable "prod_subnet_ids" {
  description = "Private subnet IDs (2 different AZs) for the production MWAA environment."
  type        = list(string)
}

variable "dev_subnet_ids" {
  description = "Private subnet IDs for the development MWAA environment."
  type        = list(string)
}

variable "prod_security_group_ids" {
  description = "Security group IDs for the production MWAA environment."
  type        = list(string)
}

variable "dev_security_group_ids" {
  description = "Security group IDs for the development MWAA environment."
  type        = list(string)
}

variable "tags" {
  description = "Default resource tags."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "tf-aws-data-e-mwaa"
  }
}
