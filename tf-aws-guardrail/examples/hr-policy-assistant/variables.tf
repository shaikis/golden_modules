variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "peopleops"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "employee-assistant"
}

variable "owner" {
  type    = string
  default = "people-technology"
}

variable "cost_center" {
  type    = string
  default = "CC-HR-01"
}
