variable "aws_region_primary" {
  type    = string
  default = "us-east-1"
}
variable "aws_region_dr" {
  type    = string
  default = "us-west-2"
}

variable "name" {
  type    = string
  default = "platform"
}
variable "name_prefix" {
  type    = string
  default = "prod"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "project" {
  type    = string
  default = "platform"
}
variable "owner" {
  type    = string
  default = ""
}
variable "cost_center" {
  type    = string
  default = "CC-400"
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
  default = "db.r6g.large"
}

variable "db_subnet_group_name" {
  type    = string
  default = ""
}
variable "dr_db_subnet_group_name" {
  type    = string
  default = ""
}
variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
variable "dr_vpc_security_group_ids" {
  type    = list(string)
  default = []
}

variable "manage_master_user_password" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 30
}
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "autoscaling_enabled" {
  type    = bool
  default = true
}
variable "autoscaling_min_capacity" {
  type    = number
  default = 1
}
variable "autoscaling_max_capacity" {
  type    = number
  default = 8
}
variable "autoscaling_target_cpu" {
  type    = number
  default = 70
}

variable "performance_insights_enabled" {
  type    = bool
  default = true
}
variable "performance_insights_retention_period" {
  type    = number
  default = 7
}

variable "create_cluster_parameter_group" {
  type    = bool
  default = true
}
variable "cluster_parameter_group_family" {
  type    = string
  default = "aurora-postgresql15"
}
variable "cluster_parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = [
    { name = "log_connections";    value = "1" },
    { name = "log_disconnections"; value = "1" },
  ]
}

variable "primary_cluster_instances" {
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
    "1" = { promotion_tier = 0 }
    "2" = { promotion_tier = 1 }
    "3" = { promotion_tier = 1 }
  }
}

variable "dr_cluster_instances" {
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
    "1" = { promotion_tier = 0 }
    "2" = { promotion_tier = 1 }
  }
}
