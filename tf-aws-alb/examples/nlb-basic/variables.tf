variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "example-nlb"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "internal" {
  type    = bool
  default = false
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "instance_ids" {
  type    = list(string)
  default = []
}

variable "listener_port" {
  type    = number
  default = 443
}

variable "target_port" {
  type    = number
  default = 443
}

variable "tags" {
  type = map(string)
  default = {
    Terraform = "true"
  }
}
