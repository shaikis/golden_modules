variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "session-cache"
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

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "automatic_failover_enabled" {
  type    = bool
  default = false
}
variable "multi_az_enabled" {
  type    = bool
  default = false
}
variable "num_cache_clusters" {
  type    = number
  default = 1
}
