variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "data-processor"
}
variable "name_prefix" {
  type    = string
  default = "prod"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "project" {
  type    = string
  default = "analytics"
}
variable "owner" {
  type    = string
  default = "data-team"
}
variable "cost_center" {
  type    = string
  default = "CC-300"
}
variable "tags" {
  type    = map(string)
  default = {
} }

variable "description" {
  type    = string
  default = "Role for data processing Lambda functions"
}
variable "max_session_duration" {
  type    = number
  default = 7200
}

variable "trusted_role_services" {
  type    = list(string)
  default = ["lambda.amazonaws.com"]
}

variable "assume_role_conditions" {
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  default = [
    {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  ]
}

variable "managed_policy_arns" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
}

variable "s3_data_bucket" {
  type    = string
  default = "my-data-bucket"
}
