variable "name" {
  type    = string
  default = "myapp"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "eks_cluster_arn" {
  type = string
}
variable "prometheus_workspace_arn" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
