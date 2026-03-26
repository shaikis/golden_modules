variable "name" {
  type        = string
  description = "Base name for all resources."
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "claude_model_id" {
  description = "Bedrock Claude model ID to use for entity extraction."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "comprehend_language_code" {
  description = "Language code for Amazon Comprehend (en, es, fr, etc.)."
  type        = string
  default     = "en"
}

variable "lambda_memory_mb" {
  type    = number
  default = 512
}

variable "lambda_timeout_sec" {
  type    = number
  default = 300
}

variable "enable_comprehend_comparison" {
  description = "Run both Bedrock and Comprehend in parallel for comparison."
  type        = bool
  default     = true
}

variable "enable_kms_encryption" {
  description = "Encrypt S3 buckets and SQS queues with KMS."
  type        = bool
  default     = true
}

variable "enable_bedrock_guardrail" {
  description = "Create a Bedrock guardrail that filters PII (email, phone, SSN, card numbers) and harmful content on every Claude invocation. Guardrail ID is injected into Lambda automatically."
  type        = bool
  default     = true
}

variable "enable_bedrock_logging" {
  description = "Enable Bedrock model invocation logging — every Claude prompt and completion is saved to the S3 output bucket and CloudWatch for audit and compliance."
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications."
  type        = string
  default     = null
}

variable "sqs_visibility_timeout" {
  type    = number
  default = 360
}

variable "sqs_max_receive_count" {
  type    = number
  default = 3
}
