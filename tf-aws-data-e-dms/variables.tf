# ---------------------------------------------------------------------------
# Feature gates
# ---------------------------------------------------------------------------

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for DMS replication tasks."
  type        = bool
  default     = false
}

variable "create_event_subscriptions" {
  description = "Whether to create DMS event subscriptions (SNS notifications)."
  type        = bool
  default     = false
}

variable "create_certificates" {
  description = "Whether to create DMS SSL certificates for encrypted connections."
  type        = bool
  default     = false
}

variable "create_iam_roles" {
  description = "Whether to create the required DMS IAM roles (dms-vpc-role and dms-cloudwatch-logs-role)."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO foundational resources
# ---------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "ARN of an existing KMS key (from tf-aws-kms) for DMS replication instance encryption. If null, AWS-managed key is used."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Global tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Replication instances
# ---------------------------------------------------------------------------

variable "replication_instances" {
  description = "Map of DMS replication instance configurations."
  type = map(object({
    replication_instance_class   = optional(string, "dms.t3.medium")
    allocated_storage            = optional(number, 50)
    multi_az                     = optional(bool, false)
    engine_version               = optional(string, "3.5.2")
    auto_minor_version_upgrade   = optional(bool, true)
    publicly_accessible          = optional(bool, false)
    vpc_security_group_ids       = optional(list(string), [])
    replication_subnet_group_id  = optional(string, null)
    kms_key_arn                  = optional(string, null)
    preferred_maintenance_window = optional(string, "sun:04:00-sun:04:30")
    apply_immediately            = optional(bool, false)
    allow_major_version_upgrade  = optional(bool, false)
    tags                         = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

variable "endpoints" {
  description = "Map of DMS endpoint configurations."
  type = map(object({
    endpoint_type                   = string # SOURCE | TARGET
    engine_name                     = string # mysql, postgres, oracle, sqlserver, aurora, aurora-postgresql, s3, kinesis, kafka, redshift, dynamodb, mongodb, docdb, etc.
    server_name                     = optional(string, null)
    port                            = optional(number, null)
    database_name                   = optional(string, null)
    username                        = optional(string, null)
    password                        = optional(string, null)
    secrets_manager_arn             = optional(string, null)
    secrets_manager_access_role_arn = optional(string, null)
    ssl_mode                        = optional(string, "none")
    certificate_arn                 = optional(string, null)
    extra_connection_attributes     = optional(string, null)

    s3_settings = optional(object({
      bucket_name                      = string
      bucket_folder                    = optional(string, null)
      compression_type                 = optional(string, "NONE")
      data_format                      = optional(string, "csv")
      parquet_version                  = optional(string, "parquet-2-0")
      enable_statistics                = optional(bool, true)
      include_op_for_full_load         = optional(bool, true)
      timestamp_column_name            = optional(string, null)
      service_access_role_arn          = optional(string, null)
      cdc_inserts_only                 = optional(bool, false)
      cdc_inserts_and_updates          = optional(bool, false)
      encoding_type                    = optional(string, "plain")
      dict_page_size_limit             = optional(number, 1048576)
      row_group_length                 = optional(number, 10000)
      data_page_size                   = optional(number, 1048576)
      parquet_timestamp_in_millisecond = optional(bool, false)
      use_csv_no_sup_value             = optional(bool, false)
    }), null)

    kinesis_settings = optional(object({
      stream_arn                     = string
      message_format                 = optional(string, "json")
      service_access_role_arn        = optional(string, null)
      include_table_alter_operations = optional(bool, true)
      include_control_details        = optional(bool, true)
      include_null_and_empty         = optional(bool, false)
      include_partition_value        = optional(bool, false)
      partition_include_schema_table = optional(bool, false)
    }), null)

    kafka_settings = optional(object({
      broker                         = string
      topic                          = optional(string, "kafka-default-topic")
      message_format                 = optional(string, "json")
      include_table_alter_operations = optional(bool, true)
      include_control_details        = optional(bool, true)
      include_null_and_empty         = optional(bool, false)
      include_partition_value        = optional(bool, false)
      partition_include_schema_table = optional(bool, false)
      ssl_client_certificate_arn     = optional(string, null)
      ssl_client_key_arn             = optional(string, null)
      ssl_ca_certificate_arn         = optional(string, null)
      security_protocol              = optional(string, "plaintext")
      sasl_username                  = optional(string, null)
      sasl_password                  = optional(string, null)
    }), null)

    redshift_settings = optional(object({
      bucket_name                       = optional(string, null)
      bucket_folder                     = optional(string, null)
      service_access_role_arn           = optional(string, null)
      server_side_encryption_kms_key_id = optional(string, null)
      encryption_mode                   = optional(string, "SSE_S3")
      accept_any_date                   = optional(bool, false)
      date_format                       = optional(string, "AUTO")
      time_format                       = optional(string, "AUTO")
      empty_as_null                     = optional(bool, true)
      trim_blanks                       = optional(bool, false)
      truncate_columns                  = optional(bool, false)
    }), null)

    mongodb_settings = optional(object({
      auth_mechanism      = optional(string, "default")
      auth_source         = optional(string, "admin")
      auth_type           = optional(string, "password")
      docs_to_investigate = optional(number, 1000)
      extract_doc_id      = optional(bool, false)
      nesting_level       = optional(string, "none")
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Replication tasks
# ---------------------------------------------------------------------------

variable "replication_tasks" {
  description = "Map of DMS replication task configurations."
  type = map(object({
    replication_instance_key  = string
    source_endpoint_key       = string
    target_endpoint_key       = string
    migration_type            = optional(string, "full-load-and-cdc")
    table_mappings            = optional(string, null) # JSON table mapping rules
    replication_task_settings = optional(string, null) # JSON task settings
    start_replication_task    = optional(bool, false)
    cdc_start_time            = optional(string, null) # RFC3339 timestamp
    tags                      = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Event subscriptions
# ---------------------------------------------------------------------------

variable "event_subscriptions" {
  description = "Map of DMS event subscription configurations."
  type = map(object({
    sns_topic_arn    = string
    source_type      = optional(string, "replication-task") # replication-instance | replication-task | replication-subnet-group
    source_ids       = optional(list(string), [])
    event_categories = optional(list(string), [])
    enabled          = optional(bool, true)
    tags             = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# SSL certificates
# ---------------------------------------------------------------------------

variable "certificates" {
  description = "Map of DMS SSL certificate configurations."
  type = map(object({
    certificate_id     = string
    certificate_pem    = optional(string, null) # PEM-encoded certificate
    certificate_wallet = optional(string, null) # Base64 binary .sso file (Oracle wallets)
    tags               = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Replication subnet group
# ---------------------------------------------------------------------------

variable "subnet_groups" {
  description = "Map of DMS replication subnet group configurations."
  type = map(object({
    description = optional(string, "")
    subnet_ids  = list(string)
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Alarm thresholds
# ---------------------------------------------------------------------------

variable "alarm_cdc_latency_source_threshold" {
  description = "Threshold in seconds for CDCLatencySource alarm."
  type        = number
  default     = 60
}

variable "alarm_cdc_latency_target_threshold" {
  description = "Threshold in seconds for CDCLatencyTarget alarm."
  type        = number
  default     = 60
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms."
  type        = number
  default     = 3
}

variable "alarm_period_seconds" {
  description = "Alarm metric evaluation period in seconds."
  type        = number
  default     = 300
}
