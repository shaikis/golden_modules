variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "company-dev-app-data-bucket"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "demo"
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}