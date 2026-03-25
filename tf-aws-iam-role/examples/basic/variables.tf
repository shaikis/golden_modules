variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "app-server"
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

variable "trusted_role_services" {
  type    = list(string)
  default = ["ec2.amazonaws.com"]
}
variable "create_instance_profile" {
  type    = bool
  default = true
}

variable "managed_policy_arns" {
  type    = list(string)
  default = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}
