variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "prod"
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

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type    = string
  default = null
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "iam_instance_profile_name" {
  type    = string
  default = null
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "target_group_arns" {
  description = "Existing ALB/NLB target group ARNs to attach the ASG to."
  type        = list(string)
}

variable "enable_cpu_scaling" {
  type    = bool
  default = true
}

variable "cpu_target_value" {
  type    = number
  default = 60
}

variable "enable_alb_request_scaling" {
  type    = bool
  default = false
}

variable "alb_request_target_value" {
  type    = number
  default = 1000
}

variable "alb_target_group_arn_suffix" {
  type    = string
  default = null
}

variable "alb_arn_suffix" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
