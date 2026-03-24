variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (from tf-aws-kms)."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications."
  type        = string
  default     = null
}

variable "prod_subnet_ids" {
  description = "Subnet IDs for the production cluster."
  type        = list(string)
  default     = ["subnet-prod1", "subnet-prod2", "subnet-prod3"]
}

variable "dev_subnet_ids" {
  description = "Subnet IDs for the dev cluster."
  type        = list(string)
  default     = ["subnet-dev1", "subnet-dev2"]
}

variable "prod_security_group_ids" {
  description = "Security group IDs for the production cluster."
  type        = list(string)
  default     = ["sg-prod-redshift"]
}

variable "dev_security_group_ids" {
  description = "Security group IDs for the dev cluster."
  type        = list(string)
  default     = ["sg-dev-redshift"]
}

variable "analytics_consumer_account_id" {
  description = "AWS account ID of the analytics consumer for data sharing."
  type        = string
  default     = "123456789012"
}

variable "tags" {
  description = "Default tags for all resources."
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "data-warehouse"
    ManagedBy   = "Terraform"
    Owner       = "data-platform-team"
  }
}
