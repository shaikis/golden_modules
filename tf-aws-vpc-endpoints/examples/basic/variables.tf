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
variable "vpc_id" {
  type    = string
  default = ""
}
variable "default_subnet_ids" {
  type    = list(string)
  default = []
}
variable "default_security_group_ids" {
  type    = list(string)
  default = []
}
variable "default_route_table_ids" {
  type    = list(string)
  default = []
}

variable "endpoints" {
  type = map(object({
    service_name       = string
    vpc_endpoint_type  = optional(string, "Interface")
    subnet_ids         = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    route_table_ids    = optional(list(string), [])
    private_dns        = optional(bool, true)
    policy             = optional(string, null)
  }))
  default = {}
}
