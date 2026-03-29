variable "name"                          { type = string; default = "myapp" }
variable "environment"                   { type = string; default = "prod" }
variable "project"                       { type = string; default = "" }
variable "owner"                         { type = string; default = "" }
variable "cost_center"                   { type = string; default = "" }
variable "alb_dns_name"                  { type = string; description = "ALB DNS name for the application API origin" }
variable "cloudfront_secret_header_value" { type = string; description = "Secret value injected as X-CloudFront-Secret header to lock down the ALB" }
variable "domain_names"                  { type = list(string); default = [] }
variable "acm_certificate_arn"           { type = string; default = null }
variable "price_class"                   { type = string; default = "PriceClass_100" }
variable "waf_web_acl_arn"               { type = string; default = null }
variable "log_bucket"                    { type = string; default = null; description = "S3 bucket domain name for CloudFront access logs" }
