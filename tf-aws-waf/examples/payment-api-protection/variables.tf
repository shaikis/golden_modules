variable "name"        { type = string; default = "acme-pay" }
variable "environment" { type = string; default = "prod" }
variable "project"     { type = string; default = "realtime-payments" }
variable "owner"       { type = string; default = "payments-security" }
variable "cost_center" { type = string; default = "CC-PAYMENTS" }

variable "trusted_partner_cidrs" {
  type        = list(string)
  description = "CIDR ranges of trusted partner bank connections (bypass rate limits)"
  default     = []
}

variable "monitoring_cidrs" {
  type        = list(string)
  description = "Internal monitoring tool CIDRs"
  default     = []
}

variable "rate_limit_per_5min" {
  type        = number
  description = "Max requests per IP per 5-minute window"
  default     = 5000
}

variable "waf_log_bucket_arn" {
  type        = string
  description = "S3 bucket ARN for WAF logs (name must start with aws-waf-logs-)"
  default     = null
}
