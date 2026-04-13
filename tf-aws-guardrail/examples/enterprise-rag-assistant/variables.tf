variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "acme-internal"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "knowledge-assistant"
}

variable "owner" {
  type    = string
  default = "enterprise-platform"
}

variable "cost_center" {
  type    = string
  default = "CC-SEC-01"
}
