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
variable "platform" {
  type    = string
  default = "Linux"
}
variable "recipe_version" {
  type    = string
  default = "1.0.0"
}
variable "root_volume_size" {
  type    = number
  default = 30
}
variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
variable "subnet_id" {
  type    = string
  default = null
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "pipeline_schedule_expression" {
  type    = string
  default = null
}
variable "pipeline_enabled" {
  type    = bool
  default = true
}
variable "distribution_regions" {
  type    = list(string)
  default = []
}
