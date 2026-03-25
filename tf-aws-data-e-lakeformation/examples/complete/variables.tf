variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID."
  type        = string
  default     = "123456789012"
}

variable "environment" {
  description = "Deployment environment name (prod, staging, dev)."
  type        = string
  default     = "prod"
}

variable "admin_role_arn" {
  description = "ARN of the Lake Formation data administrator IAM role."
  type        = string
  default     = "arn:aws:iam::123456789012:role/DataLakeAdmin"
}

variable "analyst_role_arn" {
  description = "ARN of the data analyst IAM role."
  type        = string
  default     = "arn:aws:iam::123456789012:role/DataAnalyst"
}

variable "engineer_role_arn" {
  description = "ARN of the data engineer IAM role."
  type        = string
  default     = "arn:aws:iam::123456789012:role/DataEngineer"
}

variable "tags" {
  description = "Common tags for all resources."
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Team        = "data-platform"
  }
}
