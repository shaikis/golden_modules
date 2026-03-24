variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "web-server"
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

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "subnet_id" {
  type    = string
  default = ""
}
variable "key_name" {
  type    = string
  default = null
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}
variable "monitoring" {
  type    = bool
  default = true
}
variable "disable_api_termination" {
  type    = bool
  default = false
}
