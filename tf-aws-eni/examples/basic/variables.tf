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

variable "network_interfaces" {
  type = map(object({
    subnet_id          = string
    security_group_ids = optional(list(string), [])
    private_ips        = optional(list(string), [])
    source_dest_check  = optional(bool, true)
    description        = optional(string, "")
    attachment = optional(object({
      instance_id  = string
      device_index = number
    }), null)
    eip = optional(object({
      domain                    = optional(string, "vpc")
      associate_with_private_ip = optional(string, null)
    }), null)
  }))
  default = {}
}
