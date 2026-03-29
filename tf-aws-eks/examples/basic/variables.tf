variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "dev-cluster"
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
  default = {}
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "vpc_id" {
  type    = string
  default = ""
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}
variable "endpoint_private_access" {
  type    = bool
  default = true
}
variable "public_access_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "node_groups" {
  type = map(object({
    ami_type        = optional(string, "AL2_x86_64")
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "ON_DEMAND")
    disk_size       = optional(number, 50)
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 5)
    max_unavailable = optional(number, 1)
    subnet_ids      = optional(list(string), [])
    labels          = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, null)
      effect = string
    })), [])
    kms_key_arn             = optional(string, null)
    launch_template_id      = optional(string, null)
    launch_template_version = optional(string, null)
  }))
  default = {
    general = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }
}
