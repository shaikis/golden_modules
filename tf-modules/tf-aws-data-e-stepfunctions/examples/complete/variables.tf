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

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "lambda_function_arns" {
  description = "Lambda function ARNs for the real-time processor."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Default resource tags."
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Module      = "tf-aws-data-e-stepfunctions"
  }
}
