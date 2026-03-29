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
variable "instance_type" {
  type    = string
  default = "t3.medium"
}
variable "subnet_ids" {
  type    = list(string)
  default = []
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
  default = 1
}
variable "max_size" {
  type    = number
  default = 4
}
variable "desired_capacity" {
  type    = number
  default = 2
}
variable "enable_cpu_scaling" {
  type    = bool
  default = true
}
variable "cpu_target_value" {
  type    = number
  default = 70
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "scheduled_actions" {
  type = map(object({
    recurrence       = optional(string, null)
    start_time       = optional(string, null)
    end_time         = optional(string, null)
    min_size         = optional(number, null)
    max_size         = optional(number, null)
    desired_capacity = optional(number, null)
    time_zone        = optional(string, "UTC")
  }))
  default = {}
}
