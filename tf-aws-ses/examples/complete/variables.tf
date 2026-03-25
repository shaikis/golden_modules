variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "inbound_bucket_name" {
  description = "S3 bucket name that receives inbound SES mail."
  type        = string
}

variable "sns_bounce_topic_arn" {
  description = "SNS topic ARN for bounce/complaint notifications."
  type        = string
}

variable "sns_inbound_topic_arn" {
  description = "SNS topic ARN for inbound receipt rule notifications."
  type        = string
}

variable "firehose_stream_arn" {
  description = "Kinesis Firehose delivery stream ARN for marketing email events."
  type        = string
}

variable "inbound_processor_lambda_arn" {
  description = "Lambda function ARN that processes inbound email."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Project     = "email-platform"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
