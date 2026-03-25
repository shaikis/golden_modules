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

variable "fifo_topic" {
  type    = bool
  default = false
}
variable "content_based_deduplication" {
  type    = bool
  default = false
}
variable "display_name" {
  type    = string
  default = null
}
variable "kms_master_key_id" {
  type    = string
  default = null
}
variable "delivery_policy" {
  type    = string
  default = null
}
variable "topic_policy" {
  type    = string
  default = ""
}

variable "subscriptions" {
  description = "Map of subscriptions."
  type = map(object({
    protocol                        = string
    endpoint                        = string
    raw_message_delivery            = optional(bool, false)
    filter_policy                   = optional(string, null)
    filter_policy_scope             = optional(string, null)
    redrive_policy                  = optional(string, null)
    confirmation_timeout_in_minutes = optional(number, 1)
  }))
  default = {}
}
