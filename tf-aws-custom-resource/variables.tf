variable "name" {
  description = "Name for the custom resource and related CloudFormation stack."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to the name."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags applied to the Lambda function and IAM role."
  type        = map(string)
  default     = {}
}

# ── Lambda ─────────────────────────────────────────────────────────────────────
variable "lambda_arn" {
  description = <<-EOT
    ARN of an existing Lambda function to use as the custom resource handler.
    When provided, the module does NOT create a Lambda — it uses yours.
    When null, set create_lambda = true and provide handler_code.
  EOT
  type    = string
  default = null
}

variable "create_lambda" {
  description = "Create a Lambda function from handler_code. Set to false when lambda_arn is provided."
  type        = bool
  default     = true
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "memory_size" {
  description = "Lambda memory in MB."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds. Must be less than CloudFormation stack timeout."
  type        = number
  default     = 300
}

variable "lambda_role_arn" {
  description = "IAM role ARN for the Lambda function. When null a role is created automatically."
  type        = string
  default     = null
}

variable "additional_policy_statements" {
  description = "Additional IAM policy statements added to the auto-created Lambda role."
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting Lambda environment variables."
  type        = string
  default     = null
}

# ── Custom Resource ────────────────────────────────────────────────────────────
variable "resource_type" {
  description = "CloudFormation Custom Resource type suffix (e.g. 'DevOpsAgentSpace', 'AMPScraper'). Full type = Custom::<resource_type>."
  type        = string
  default     = "CustomResource"
}

variable "properties" {
  description = <<-EOT
    Properties passed to the Custom Resource Lambda on Create/Update.
    All values must be strings. The Lambda receives these in event.ResourceProperties.
    Example:
      properties = {
        AgentSpaceName  = "my-agent-space"
        EksClusterArn   = "arn:aws:eks:us-east-1:123456789012:cluster/my-cluster"
        PrometheusArn   = "arn:aws:aps:us-east-1:123456789012:workspace/ws-abc123"
      }
  EOT
  type    = map(string)
  default = {}
}

variable "output_attributes" {
  description = <<-EOT
    Map of Terraform output name => Lambda response attribute name.
    The Lambda must return these attributes in the Data field of its cfnresponse.
    Example:
      output_attributes = {
        agent_space_id  = "AgentSpaceId"
        agent_space_arn = "AgentSpaceArn"
      }
  EOT
  type    = map(string)
  default = {}
}

variable "stack_timeout_minutes" {
  description = "CloudFormation stack creation timeout in minutes."
  type        = number
  default     = 30
}

variable "trigger_on_change" {
  description = "Extra value used to force re-invocation of the custom resource on every apply. Set to timestamp() for always-run or a hash for change-triggered."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the Lambda function."
  type        = number
  default     = 14
}
