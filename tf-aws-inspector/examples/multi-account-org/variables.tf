variable "aws_region"            { type = string; default = "us-east-1" }
variable "name"                  { type = string; default = "enterprise" }
variable "environment"           { type = string; default = "prod" }
variable "project"               { type = string; default = "org-security" }
variable "owner"                 { type = string; default = "central-security" }
variable "cost_center"           { type = string; default = "CC-SECURITY-001" }
variable "kms_key_arn"           { type = string }
variable "security_account_id"   { type = string; description = "Security (delegated admin) AWS account ID" }
variable "engineering_account_id" { type = string }
variable "finance_account_id"    { type = string }
variable "hr_account_id"         { type = string }
variable "marketing_account_id"  { type = string }
