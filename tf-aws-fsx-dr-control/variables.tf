variable "name" {
  description = "Base name for DR control resources."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project or product name."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Resource owner."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

variable "lambda_subnet_ids" {
  description = "Private subnets for the DR controller Lambda. Set when ONTAP management IPs are reachable only inside the VPC."
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "Security groups for the DR controller Lambda."
  type        = list(string)
  default     = []
}

variable "allowed_secret_arns" {
  description = "Secrets Manager secret ARNs the controller Lambda may read. Each secret should contain hostname, username, password, and optional port."
  type        = list(string)
  default     = []
}

variable "create_state_table" {
  description = "Create a DynamoDB table to track active DR state and workflow history."
  type        = bool
  default     = true
}

variable "state_table_name" {
  description = "Optional existing DynamoDB table name for DR state. When create_state_table is true and this is null, the module creates one."
  type        = string
  default     = null
}

variable "dns" {
  description = "Optional Route 53 record details for DR cutover."
  type = object({
    zone_id     = string
    record_name = string
    record_type = optional(string, "CNAME")
    ttl         = optional(number, 30)
  })
  default = null
}

variable "notification_topic_arn" {
  description = "Optional SNS topic ARN for workflow notifications."
  type        = string
  default     = null
}

variable "lambda_timeout_seconds" {
  description = "Timeout for the controller Lambda."
  type        = number
  default     = 120
}

variable "lambda_memory_size" {
  description = "Memory size for the controller Lambda."
  type        = number
  default     = 256
}

variable "cloudwatch_log_retention_days" {
  description = "Log retention for Lambda and Step Functions log groups."
  type        = number
  default     = 30
}
