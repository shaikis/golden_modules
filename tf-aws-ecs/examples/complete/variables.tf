variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "platform-ecs"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "platform"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "cost_center" {
  type    = string
  default = "CC-500"
}

variable "tags" {
  type = map(string)
  default = {
    Tier = "application"
  }
}

variable "vpc_id" {
  type    = string
  default = "vpc-1234567890abcdef0"
}

variable "efs_subnet_ids" {
  type    = list(string)
  default = ["subnet-11111111", "subnet-22222222"]
}

variable "service_subnet_ids" {
  type    = list(string)
  default = ["subnet-11111111", "subnet-22222222"]
}

variable "service_security_group_ids" {
  type    = list(string)
  default = ["sg-1234567890abcdef0"]
}

variable "api_image" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:stable"
}

variable "worker_image" {
  type    = string
  default = "public.ecr.aws/docker/library/busybox:latest"
}
