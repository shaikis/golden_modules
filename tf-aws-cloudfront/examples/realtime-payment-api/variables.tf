variable "aws_region"           { type = string; default = "us-east-1" }
variable "name"                 { type = string; default = "acme-pay" }
variable "environment"          { type = string; default = "prod" }
variable "project"              { type = string; default = "realtime-payments" }
variable "owner"                { type = string; default = "payments-platform" }
variable "cost_center"          { type = string; default = "CC-PAYMENTS" }
variable "api_gateway_domain"   { type = string; description = "API Gateway domain (e.g. abc123.execute-api.us-east-1.amazonaws.com)" }
variable "api_domain_name"      { type = string; default = null }
variable "acm_certificate_arn"  { type = string; default = null }
variable "origin_verify_secret" { type = string; default = "REPLACE_WITH_SECRET" }
