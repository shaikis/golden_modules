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
  type    = map(string)
  default = {
} }

variable "fifo_queue" {
  type    = bool
  default = false
}
variable "content_based_deduplication" {
  type    = bool
  default = false
}
variable "deduplication_scope" {
  type    = string
  default = null
}
variable "fifo_throughput_limit" {
  type    = string
  default = null
}
variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}
variable "message_retention_seconds" {
  type    = number
  default = 345600
} # 4 days
variable "max_message_size" {
  type    = number
  default = 262144
}  # 256 KB
variable "delay_seconds" {
  type    = number
  default = 0
}
variable "receive_wait_time_seconds" {
  type    = number
  default = 0
}

variable "kms_master_key_id" {
  description = "KMS key ID/ARN/alias for SSE."
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  type    = number
  default = 300
}

variable "create_dlq" {
  description = "Create a Dead Letter Queue."
  type        = bool
  default     = true
}

variable "dlq_message_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}

variable "maxReceiveCount" {
  description = "Max receive count before message goes to DLQ."
  type        = number
  default     = 5
}

variable "queue_policy" {
  description = "Custom JSON queue policy."
  type        = string
  default     = ""
}
