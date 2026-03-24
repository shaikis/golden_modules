variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "my-app-db"
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

variable "engine" {
  type    = string
  default = "postgres"
}
variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_subnet_group_name" {
  type    = string
  default = ""
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "skip_final_snapshot" {
  type    = bool
  default = true
}
variable "deletion_protection" {
  type    = bool
  default = false
}
