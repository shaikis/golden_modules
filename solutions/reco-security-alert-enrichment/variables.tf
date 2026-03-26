# ── Identity ───────────────────────────────────────────────────────────────────
variable "name" {
  description = "Base name for all resources (e.g. 'reco', 'myapp')."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ── Bedrock / Claude ───────────────────────────────────────────────────────────
variable "claude_model_id" {
  description = "Bedrock Claude model ID used for alert enrichment."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "enable_bedrock_guardrail" {
  description = "Create a Bedrock guardrail that filters PII and harmful content on every Claude invocation. Guardrail ID is injected into Lambda automatically."
  type        = bool
  default     = true
}

variable "enable_bedrock_logging" {
  description = "Enable Bedrock model invocation logging — every Claude prompt and completion is saved to the S3 output bucket and CloudWatch for audit and compliance."
  type        = bool
  default     = true
}

# ── Lambda ─────────────────────────────────────────────────────────────────────
variable "lambda_memory_mb" {
  description = "Lambda function memory in MB."
  type        = number
  default     = 512
}

variable "lambda_timeout_sec" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 300
}

# ── SQS ────────────────────────────────────────────────────────────────────────
variable "sqs_visibility_timeout" {
  description = "SQS message visibility timeout in seconds. Should be >= lambda_timeout_sec."
  type        = number
  default     = 360
}

variable "sqs_max_receive_count" {
  description = "Max SQS receive attempts before routing to Dead Letter Queue."
  type        = number
  default     = 3
}

# ── Security ───────────────────────────────────────────────────────────────────
variable "enable_kms_encryption" {
  description = "Encrypt S3 buckets and SQS queues with a customer-managed KMS key."
  type        = bool
  default     = true
}

# ── Alerting ───────────────────────────────────────────────────────────────────
variable "alarm_email" {
  description = "Email address for CloudWatch alarm and high-severity alert SNS notifications. Set to null to disable."
  type        = string
  default     = null
}
