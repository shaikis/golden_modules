variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Lambda function name."
  type        = string
  default     = "my-lambda"
}

variable "name_prefix" {
  description = "Prefix prepended to all resource names."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "myapp"
}

variable "owner" {
  description = "Owning team."
  type        = string
  default     = ""
}

variable "description" {
  description = "Lambda function description."
  type        = string
  default     = "Basic Lambda function"
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}

# ── IAM Role ──────────────────────────────────────────────────────────────────
# Option A (default): create_role = true  + role_arn = null  → module creates a new role
# Option B:           create_role = false + role_arn = "arn" → reuse an existing role
variable "create_role" {
  description = "Set true to auto-create the execution role. Set false and provide role_arn to reuse an existing role."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Existing IAM execution role ARN. When provided, create_role is ignored and no new role is created."
  type        = string
  default     = null
}

# ── Runtime ───────────────────────────────────────────────────────────────────
variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Function handler (file.function)."
  type        = string
  default     = "index.handler"
}

variable "memory_size" {
  description = "Memory allocated in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 30
}

variable "filename" {
  description = "Path to local zip deployment package."
  type        = string
  default     = "lambda.zip"
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

# ── CloudWatch ────────────────────────────────────────────────────────────────
variable "log_retention_days" {
  description = "Log retention period in days."
  type        = number
  default     = 30
}

variable "create_cloudwatch_alarms" {
  description = "Create error and throttle alarms."
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications."
  type        = string
  default     = null
}

variable "alarm_error_threshold" {
  description = "Error count that triggers the alarm."
  type        = number
  default     = 1
}
