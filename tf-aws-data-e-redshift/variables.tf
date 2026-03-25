# ── Global ────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Default tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ── Feature Gates ─────────────────────────────────────────────────────────────

variable "create_serverless" {
  description = "Enable Redshift Serverless namespaces and workgroups."
  type        = bool
  default     = false
}

variable "create_subnet_groups" {
  description = "Create Redshift cluster subnet groups."
  type        = bool
  default     = true
}

variable "create_parameter_groups" {
  description = "Create Redshift cluster parameter groups."
  type        = bool
  default     = false
}

variable "create_snapshot_schedules" {
  description = "Create snapshot schedules and associate them with clusters."
  type        = bool
  default     = false
}

variable "create_scheduled_actions" {
  description = "Create scheduled actions (pause/resume/resize) for clusters."
  type        = bool
  default     = false
}

variable "create_data_shares" {
  description = "Create Redshift data share authorizations and consumer associations."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Create CloudWatch alarms for Redshift clusters and serverless workgroups."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Create IAM roles for Redshift service and scheduled actions."
  type        = bool
  default     = true
}

# ── BYO Foundational ─────────────────────────────────────────────────────────

variable "role_arn" {
  description = "BYO IAM role ARN (from tf-aws-iam). Used when create_iam_role = false."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "BYO KMS key ARN (from tf-aws-kms) for encryption."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

# ── Clusters ──────────────────────────────────────────────────────────────────

variable "clusters" {
  description = "Map of provisioned Redshift cluster configurations."
  type = map(object({
    database_name                        = optional(string, "dev")
    master_username                      = optional(string, "admin")
    node_type                            = optional(string, "ra3.xlplus")
    cluster_type                         = optional(string, "multi-node")
    number_of_nodes                      = optional(number, 2)
    subnet_group_key                     = optional(string, null)
    parameter_group_key                  = optional(string, null)
    vpc_security_group_ids               = optional(list(string), [])
    encrypted                            = optional(bool, true)
    kms_key_id                           = optional(string, null)
    enhanced_vpc_routing                 = optional(bool, true)
    publicly_accessible                  = optional(bool, false)
    manage_master_password               = optional(bool, true)
    master_password                      = optional(string, null)
    automated_snapshot_retention_period  = optional(number, 7)
    preferred_maintenance_window         = optional(string, "sun:05:00-sun:06:00")
    logging_enabled                      = optional(bool, true)
    log_destination_type                 = optional(string, "cloudwatch")
    logging_bucket_name                  = optional(string, null)
    logging_s3_key_prefix                = optional(string, null)
    iam_role_keys                        = optional(list(string), [])
    additional_iam_role_arns             = optional(list(string), [])
    skip_final_snapshot                  = optional(bool, false)
    final_snapshot_identifier            = optional(string, null)
    snapshot_identifier                  = optional(string, null)
    elastic_ip                           = optional(string, null)
    availability_zone                    = optional(string, null)
    availability_zone_relocation_enabled = optional(bool, false)
    aqua_configuration_status            = optional(string, "auto")
    multi_az                             = optional(bool, false)
    tags                                 = optional(map(string), {})
  }))
  default = {}
}

# ── Subnet Groups ─────────────────────────────────────────────────────────────

variable "subnet_groups" {
  description = "Map of Redshift subnet group configurations."
  type = map(object({
    name        = optional(string, null)
    description = optional(string, "Managed by Terraform")
    subnet_ids  = list(string)
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ── Parameter Groups ──────────────────────────────────────────────────────────

variable "parameter_groups" {
  description = "Map of Redshift parameter group configurations."
  type = map(object({
    name        = optional(string, null)
    family      = optional(string, "redshift-1.0")
    description = optional(string, "Managed by Terraform")
    parameters  = optional(map(string), {})
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ── Serverless ────────────────────────────────────────────────────────────────

variable "serverless_namespaces" {
  description = "Map of Redshift Serverless namespace configurations."
  type = map(object({
    db_name               = optional(string, "dev")
    admin_username        = optional(string, "admin")
    manage_admin_password = optional(bool, true)
    admin_user_password   = optional(string, null)
    kms_key_id            = optional(string, null)
    log_exports           = optional(list(string), ["connectionlog", "useractivitylog"])
    iam_role_arns         = optional(list(string), [])
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "serverless_workgroups" {
  description = "Map of Redshift Serverless workgroup configurations."
  type = map(object({
    namespace_key        = string
    base_capacity        = optional(number, 8)
    max_capacity         = optional(number, null)
    subnet_ids           = list(string)
    security_group_ids   = list(string)
    publicly_accessible  = optional(bool, false)
    enhanced_vpc_routing = optional(bool, true)
    config_parameters    = optional(map(string), {})
    tags                 = optional(map(string), {})
  }))
  default = {}
}

# ── Snapshot Schedules ────────────────────────────────────────────────────────

variable "snapshot_schedules" {
  description = "Map of snapshot schedule configurations."
  type = map(object({
    identifier   = optional(string, null)
    description  = optional(string, null)
    definitions  = list(string)
    cluster_keys = optional(list(string), [])
    tags         = optional(map(string), {})
  }))
  default = {}
}

variable "snapshot_copy_grants" {
  description = "Map of cross-region snapshot copy grant configurations."
  type = map(object({
    snapshot_copy_grant_name = string
    kms_key_id               = optional(string, null)
    tags                     = optional(map(string), {})
  }))
  default = {}
}

# ── Scheduled Actions ─────────────────────────────────────────────────────────

variable "scheduled_actions" {
  description = "Map of scheduled action configurations (pause/resume/resize)."
  type = map(object({
    description        = optional(string, null)
    schedule           = string
    iam_role_arn       = optional(string, null)
    start_time         = optional(string, null)
    end_time           = optional(string, null)
    enable             = optional(bool, true)
    action_type        = string
    cluster_key        = optional(string, null)
    cluster_identifier = optional(string, null)
    # resize_cluster fields
    classic         = optional(bool, false)
    cluster_type    = optional(string, null)
    node_type       = optional(string, null)
    number_of_nodes = optional(number, null)
    tags            = optional(map(string), {})
  }))
  default = {}
}

# ── Data Shares ───────────────────────────────────────────────────────────────

variable "data_share_authorizations" {
  description = "Map of data share authorization configurations."
  type = map(object({
    data_share_arn      = string
    consumer_identifier = string
    allow_writes        = optional(bool, false)
  }))
  default = {}
}

variable "data_share_consumer_associations" {
  description = "Map of data share consumer association configurations."
  type = map(object({
    data_share_arn           = string
    associate_entire_account = optional(bool, false)
    consumer_arn             = optional(string, null)
    consumer_region          = optional(string, null)
  }))
  default = {}
}

# ── Alarms ────────────────────────────────────────────────────────────────────

variable "alarm_cpu_threshold" {
  description = "CPUUtilization alarm threshold (percent)."
  type        = number
  default     = 80
}

variable "alarm_connections_threshold" {
  description = "DatabaseConnections alarm threshold (count)."
  type        = number
  default     = 500
}

variable "alarm_disk_threshold" {
  description = "DiskSpaceUsedPercent alarm threshold (percent)."
  type        = number
  default     = 80
}

variable "alarm_read_latency_threshold" {
  description = "ReadLatency alarm threshold (seconds)."
  type        = number
  default     = 0.1
}

variable "alarm_write_latency_threshold" {
  description = "WriteLatency alarm threshold (seconds)."
  type        = number
  default     = 0.1
}

variable "alarm_compute_seconds_threshold" {
  description = "Serverless ComputeSeconds alarm threshold."
  type        = number
  default     = 3600
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for alarms."
  type        = number
  default     = 2
}

variable "alarm_period_seconds" {
  description = "Alarm evaluation period in seconds."
  type        = number
  default     = 300
}
