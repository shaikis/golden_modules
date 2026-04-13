variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "cityhealth"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "patient-portal"
}

variable "owner" {
  type    = string
  default = "clinical-informatics"
}

variable "cost_center" {
  type    = string
  default = "CC-HIPAA-01"
}
