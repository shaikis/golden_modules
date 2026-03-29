variable "aws_region"     { type = string; default = "us-east-1" }
variable "name"           { type = string; default = "acme" }
variable "environment"    { type = string; default = "prod" }
variable "project"        { type = string; default = "devsecops" }
variable "owner"          { type = string; default = "platform-security" }
variable "cost_center"    { type = string; default = "CC-SEC-DEVSECOPS" }
variable "pipeline_name"  { type = string; description = "CodePipeline name to gate on critical findings" }
