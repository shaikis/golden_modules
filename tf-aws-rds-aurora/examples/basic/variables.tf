variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "dev-aurora"
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
  default = "aurora-postgresql"
}
variable "engine_version" {
  type    = string
  default = "15.4"
}
variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_subnet_group_name" {
  type    = string
  default = ""
}
variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}

variable "deletion_protection" {
  type    = bool
  default = false
}
variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "cluster_instances" {
  type = map(object({
    instance_class               = optional(string, null)
    publicly_accessible          = optional(bool, false)
    availability_zone            = optional(string, null)
    auto_minor_version_upgrade   = optional(bool, true)
    performance_insights_enabled = optional(bool, true)
    monitoring_interval          = optional(number, 60)
    promotion_tier               = optional(number, 0)
    preferred_maintenance_window = optional(string, null)
  }))
  default = {
    "1" = {}
  }
}
