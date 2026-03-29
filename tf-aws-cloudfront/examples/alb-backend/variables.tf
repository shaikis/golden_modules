variable "aws_region"                    { type = string; default = "us-east-1" }
variable "name"                          { type = string; default = "myapp" }
variable "environment"                   { type = string; default = "prod" }
variable "project"                       { type = string; default = "" }
variable "owner"                         { type = string; default = "" }
variable "cost_center"                   { type = string; default = "" }
variable "alb_dns_name"                  { type = string; description = "ALB DNS name (e.g. my-alb-1234567890.us-east-1.elb.amazonaws.com)" }
variable "cloudfront_secret_header_value" { type = string; description = "Secret value for X-CloudFront-Secret header" }
variable "domain_names"                  { type = list(string); default = [] }
variable "acm_certificate_arn"           { type = string; default = null }
variable "waf_web_acl_arn"               { type = string; default = null }
variable "allowed_countries"             { type = list(string); default = null }
variable "log_bucket"                    { type = string; default = null; description = "S3 bucket domain name for access logs" }
