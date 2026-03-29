variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "app-fsx"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "platform"
}

variable "allowed_secret_arns" {
  type    = list(string)
  default = []
}

variable "route53_zone_id" {
  type = string
}

variable "route53_record_name" {
  type = string
}

variable "lambda_subnet_ids" {
  type    = list(string)
  default = []
}

variable "lambda_security_group_ids" {
  type    = list(string)
  default = []
}

variable "notification_topic_arn" {
  type    = string
  default = null
}
