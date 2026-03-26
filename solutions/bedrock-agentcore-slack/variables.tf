variable "name" {
  description = "Base name for all resources."
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

variable "slack_bot_token" {
  description = "Slack Bot User OAuth Token (xoxb-...). Stored in Secrets Manager."
  type        = string
  sensitive   = true
}

variable "slack_signing_secret" {
  description = "Slack App Signing Secret for webhook signature verification."
  type        = string
  sensitive   = true
}

variable "claude_model_id" {
  description = "Bedrock model ID for the agent."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "agent_instruction" {
  description = "System instruction for the Bedrock Agent."
  type        = string
  default     = "You are a helpful AI assistant integrated into Slack. Answer questions concisely and clearly. For general questions, provide accurate and helpful responses. Always be professional and courteous."
}

variable "enable_bedrock_guardrail" {
  description = "Enable Bedrock guardrail for PII filtering and content safety."
  type        = bool
  default     = true
}

variable "enable_bedrock_logging" {
  description = "Enable Bedrock model invocation logging to S3 and CloudWatch."
  type        = bool
  default     = true
}

variable "lambda_memory_mb" {
  description = "Lambda function memory in MB."
  type        = number
  default     = 512
}

variable "lambda_timeout_sec" {
  description = "Lambda timeout in seconds for the agent integration function."
  type        = number
  default     = 300
}

variable "sqs_visibility_timeout" {
  description = "SQS visibility timeout in seconds. Must be >= lambda_timeout_sec."
  type        = number
  default     = 360
}

variable "sqs_max_receive_count" {
  description = "Max SQS receive attempts before routing to DLQ."
  type        = number
  default     = 3
}

variable "agent_image_tag" {
  description = "Container image tag for the agent runtime image in ECR."
  type        = string
  default     = "latest"
}

variable "enable_kms_encryption" {
  description = "Encrypt all resources with a customer-managed KMS key."
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications. Null to disable."
  type        = string
  default     = null
}
