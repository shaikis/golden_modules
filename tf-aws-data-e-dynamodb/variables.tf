variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Default tags applied to every resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# DynamoDB Tables
# ---------------------------------------------------------------------------

variable "tables" {
  description = "Map of DynamoDB tables to create."
  type = map(object({
    billing_mode   = optional(string, "PAY_PER_REQUEST")
    hash_key       = string
    hash_key_type  = optional(string, "S")
    range_key      = optional(string, null)
    range_key_type = optional(string, "S")

    read_capacity  = optional(number, null)
    write_capacity = optional(number, null)

    stream_enabled     = optional(bool, false)
    stream_view_type   = optional(string, "NEW_AND_OLD_IMAGES")
    kinesis_stream_arn = optional(string, null)

    ttl_attribute = optional(string, null)

    point_in_time_recovery = optional(bool, true)
    deletion_protection    = optional(bool, true)
    table_class            = optional(string, "STANDARD")
    kms_key_arn            = optional(string, null)
    contributor_insights   = optional(bool, false)

    autoscaling = optional(object({
      min_read_capacity        = optional(number, 1)
      max_read_capacity        = optional(number, 100)
      min_write_capacity       = optional(number, 1)
      max_write_capacity       = optional(number, 100)
      target_read_utilization  = optional(number, 70)
      target_write_utilization = optional(number, 70)
    }), null)

    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      hash_key_type      = optional(string, "S")
      range_key          = optional(string, null)
      range_key_type     = optional(string, "S")
      projection_type    = optional(string, "ALL")
      non_key_attributes = optional(list(string), [])
      read_capacity      = optional(number, null)
      write_capacity     = optional(number, null)
      autoscaling = optional(object({
        min_read_capacity        = optional(number, 1)
        max_read_capacity        = optional(number, 100)
        min_write_capacity       = optional(number, 1)
        max_write_capacity       = optional(number, 100)
        target_read_utilization  = optional(number, 70)
        target_write_utilization = optional(number, 70)
      }), null)
    })), [])

    local_secondary_indexes = optional(list(object({
      name               = string
      range_key          = string
      range_key_type     = optional(string, "S")
      projection_type    = optional(string, "ALL")
      non_key_attributes = optional(list(string), [])
    })), [])

    backup_enabled = optional(bool, true)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Global Tables (multi-region replication)
# ---------------------------------------------------------------------------

variable "global_tables" {
  description = "Tables that need multi-region Global Table replication."
  type = map(object({
    hash_key       = string
    hash_key_type  = optional(string, "S")
    range_key      = optional(string, null)
    range_key_type = optional(string, "S")

    stream_view_type       = optional(string, "NEW_AND_OLD_IMAGES")
    kms_key_arn            = optional(string, null)
    point_in_time_recovery = optional(bool, true)
    deletion_protection    = optional(bool, true)

    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      hash_key_type      = optional(string, "S")
      range_key          = optional(string, null)
      range_key_type     = optional(string, "S")
      projection_type    = optional(string, "ALL")
      non_key_attributes = optional(list(string), [])
    })), [])

    replicas = list(object({
      region_name            = string
      kms_key_arn            = optional(string, null)
      point_in_time_recovery = optional(bool, true)
      propagate_tags         = optional(bool, true)
    }))

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Alarms
# ---------------------------------------------------------------------------

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms."
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to notify when alarms fire."
  type        = string
  default     = null
}

variable "latency_threshold_ms" {
  description = "P99 SuccessfulRequestLatency threshold in milliseconds."
  type        = number
  default     = 100
}

variable "replication_latency_threshold_ms" {
  description = "ReplicationLatency threshold in milliseconds for global tables."
  type        = number
  default     = 500
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------

variable "create_backup_plan" {
  description = "Whether to create an AWS Backup plan."
  type        = bool
  default     = true
}

variable "backup_vault_name" {
  description = "Name of the AWS Backup vault. Defaults to <name_prefix>-dynamodb-vault."
  type        = string
  default     = null
}

variable "backup_secondary_vault_arn" {
  description = "ARN of the secondary-region backup vault for copy actions."
  type        = string
  default     = null
}

variable "backup_vault_lock_min_retention_days" {
  description = "Minimum retention days for backup vault lock (WORM). 0 disables the lock."
  type        = number
  default     = 7
}

variable "backup_vault_lock_max_retention_days" {
  description = "Maximum retention days for backup vault lock."
  type        = number
  default     = 365
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

variable "create_iam_roles" {
  description = "Whether to create IAM roles/policies."
  type        = bool
  default     = true
}

variable "iam_role_principal_arns" {
  description = "List of IAM principal ARNs allowed to assume the created roles."
  type        = list(string)
  default     = []
}
