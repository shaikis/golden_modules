variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "my-app"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = ""
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
  default = {
} }

variable "container_image" {
  type    = string
  default = "nginx:latest"
}
variable "container_port" {
  type    = number
  default = 80
}
variable "task_cpu" {
  type    = number
  default = 256
}
variable "task_memory" {
  type    = number
  default = 512
}

variable "service_subnets" {
  type    = list(string)
  default = []
}
variable "service_security_groups" {
  type    = list(string)
  default = []
}
variable "desired_count" {
  type    = number
  default = 1
}
