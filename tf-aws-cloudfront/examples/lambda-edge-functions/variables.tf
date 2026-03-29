variable "name"                  { type = string; default = "myapp" }
variable "environment"           { type = string; default = "prod" }
variable "project"               { type = string; default = "" }
variable "owner"                 { type = string; default = "" }
variable "cost_center"           { type = string; default = "" }
variable "domain_names"          { type = list(string); default = [] }
variable "acm_certificate_arn"   { type = string; default = null }
variable "price_class"           { type = string; default = "PriceClass_100" }
variable "canary_traffic_percent" {
  type        = number
  default     = 10
  description = "Percentage of origin-request traffic routed to the canary S3 prefix by Lambda@Edge (0-100)"
  validation {
    condition     = var.canary_traffic_percent >= 0 && var.canary_traffic_percent <= 100
    error_message = "canary_traffic_percent must be between 0 and 100."
  }
}
