variable "name" {
  type = string
}
variable "name_prefix" {
  type    = string
  default = ""
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
  type = map(string)
  default = {
  }
}

# ===========================================================================
# EBS VOLUMES
# ===========================================================================
variable "volumes" {
  description = "Map of volume logical name → config."
  type = map(object({
    availability_zone    = string
    size                 = number
    type                 = optional(string, "gp3")
    iops                 = optional(number, null)
    throughput           = optional(number, null)
    multi_attach_enabled = optional(bool, false)
    snapshot_id          = optional(string, null)
    final_snapshot       = optional(bool, false)
    additional_tags      = optional(map(string), {})
  }))
  default = {}
}

variable "kms_key_arn" {
  description = "KMS key for all volume encryption."
  type        = string
  default     = null
}

# ===========================================================================
# VOLUME ATTACHMENTS
# ===========================================================================
variable "volume_attachments" {
  description = "Map of attachment key → {volume_key, instance_id, device_name}."
  type = map(object({
    volume_key                  = string
    instance_id                 = string
    device_name                 = string
    force_detach                = optional(bool, false)
    stop_instance_before_detach = optional(bool, true)
  }))
  default = {}
}

# ===========================================================================
# EBS SNAPSHOTS
# ===========================================================================
variable "snapshots" {
  description = "Manual snapshots to create from existing volumes (key → volume_id)."
  type = map(object({
    volume_id   = string
    description = optional(string, "")
    permanent   = optional(bool, false) # prevent_destroy
  }))
  default = {}
}

variable "snapshot_copy" {
  description = "Cross-region snapshot copies."
  type = map(object({
    source_snapshot_id = string
    source_region      = string
    description        = optional(string, "")
    kms_key_id         = optional(string, null)
  }))
  default = {}
}

# ===========================================================================
# DLM LIFECYCLE POLICY
# ===========================================================================
variable "enable_dlm" {
  description = "Create an Amazon DLM lifecycle policy for automated snapshots."
  type        = bool
  default     = false
}

variable "dlm_target_tags" {
  description = "Instance or volume tags to target with the DLM policy."
  type        = map(string)
  default     = {}
}

variable "dlm_schedules" {
  description = "DLM schedule definitions."
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
      interval     = 24
      times        = ["02:00"]
      retain_count = 7
    }
  ]
}

variable "dlm_target_resource_type" {
  description = "VOLUME or INSTANCE."
  type        = string
  default     = "VOLUME"
}
