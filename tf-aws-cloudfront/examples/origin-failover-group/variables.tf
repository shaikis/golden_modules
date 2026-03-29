variable "name"               { type = string; default = "myapp" }
variable "environment"       { type = string; default = "prod" }
variable "project"           { type = string; default = "" }
variable "owner"             { type = string; default = "" }
variable "cost_center"       { type = string; default = "" }
variable "domain_names"      { type = list(string); default = [] }
variable "acm_certificate_arn" { type = string; default = null }
variable "price_class"       { type = string; default = "PriceClass_100" }
variable "log_bucket"        { type = string; default = null; description = "S3 bucket domain name for CloudFront access logs" }
variable "alarm_sns_arn"     { type = string; default = null; description = "SNS topic ARN to notify when the 5xx error rate alarm fires" }
