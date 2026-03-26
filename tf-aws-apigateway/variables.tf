variable "name" {
  description = "Name of the API Gateway."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to the name."
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the API."
  type        = string
  default     = "Managed by Terraform"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}

variable "protocol_type" {
  description = "API protocol type. HTTP or WEBSOCKET."
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "WEBSOCKET"], var.protocol_type)
    error_message = "protocol_type must be HTTP or WEBSOCKET."
  }
}

variable "stage_name" {
  description = "Name of the deployment stage."
  type        = string
  default     = "$default"
}

variable "auto_deploy" {
  description = "Automatically deploy changes to the stage."
  type        = bool
  default     = true
}

variable "cors_configuration" {
  description = "CORS configuration for the API. Set to null to disable."
  type = object({
    allow_headers  = optional(list(string), ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Slack-Signature", "X-Slack-Request-Timestamp"])
    allow_methods  = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    allow_origins  = optional(list(string), ["*"])
    expose_headers = optional(list(string), [])
    max_age        = optional(number, 300)
  })
  default = null
}

variable "routes" {
  description = "Map of API routes to Lambda integrations. Key format: 'METHOD /path' (e.g. 'POST /slack/events')."
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
    timeout_milliseconds = optional(number, 29000)
    authorization_type   = optional(string, "NONE")
    authorizer_id        = optional(string, null)
  }))
  default = {}
}

variable "enable_access_logs" {
  description = "Enable CloudWatch access logging for the stage."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "default_route_settings" {
  description = "Default throttling and logging settings for all routes."
  type = object({
    throttling_burst_limit   = optional(number, 5000)
    throttling_rate_limit    = optional(number, 10000)
    detailed_metrics_enabled = optional(bool, false)
  })
  default = {}
}
