variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "company-dev-app-data-bucket"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "demo"
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

variable "volumes" {
  type = map(object({
    availability_zone = string
    size              = number
    type              = optional(string, "gp3")
    iops              = optional(number, null)
    throughput        = optional(number, null)
  }))
  default = {}
}

variable "volume_attachments" {
  type = map(object({
    volume_key  = string
    instance_id = string
    device_name = string
  }))
  default = {}
}

variable "enable_dlm" {
  type    = bool
  default = false
}
variable "dlm_target_tags" {
  type    = map(string)
  default = {}
}

variable "dlm_schedules" {
  type = list(object({
    name          = string
    interval      = optional(number, 24)
    interval_unit = optional(string, "HOURS")
    times         = optional(list(string), ["02:00"])
    retain_count  = optional(number, 7)
    copy_tags     = optional(bool, true)
    cross_region_copy_rule = optional(object({
      target          = string
      encrypted       = optional(bool, true)
      retain_interval = optional(number, 7)
      retain_unit     = optional(string, "DAYS")
    }), null)
  }))
  default = [
    {
      name         = "daily"
      retain_count = 7
    }
  ]
}
