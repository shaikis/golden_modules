variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all named resources."
  type        = string
  default     = "prod"
}

variable "results_bucket_name" {
  description = "Name of the S3 bucket where Athena writes query results."
  type        = string
}

variable "results_bucket_arn" {
  description = "ARN of the S3 bucket where Athena writes query results."
  type        = string
}

variable "data_lake_bucket_name" {
  description = "Name of the S3 data lake bucket."
  type        = string
}

variable "data_lake_bucket_arn" {
  description = "ARN of the S3 data lake bucket."
  type        = string
}

variable "results_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Athena query results."
  type        = string
}

variable "lambda_connector_arn" {
  description = "ARN of the Lambda function acting as a federated query connector."
  type        = string
}

variable "account_id" {
  description = "AWS account ID (used for expected_bucket_owner)."
  type        = string
}

variable "tags" {
  description = "Tags merged into every taggable resource."
  type        = map(string)
  default = {
    Environment = "production"
    Team        = "data-platform"
    ManagedBy   = "terraform"
  }
}
