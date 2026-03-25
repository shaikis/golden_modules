# ---------------------------------------------------------------------------
# Feature Gates
# ---------------------------------------------------------------------------
# Only the resources you opt into will be created.
# A minimal setup only needs kinesis_streams — everything else is optional.

variable "create_firehose_streams" {
  description = "Set true to create Kinesis Firehose delivery streams."
  type        = bool
  default     = false
}

variable "create_analytics_applications" {
  description = "Set true to create Kinesis Data Analytics (Flink) applications."
  type        = bool
  default     = false
}

variable "create_stream_consumers" {
  description = "Set true to create Enhanced Fan-Out (EFO) stream consumers."
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for streams and Firehose. Requires alarm_sns_topic_arn."
  type        = bool
  default     = false
}

variable "create_iam_roles" {
  description = "Set true to auto-create scoped IAM roles (producer, consumer, firehose, analytics)."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Global
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Default tags merged into every resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Kinesis Data Streams
# ---------------------------------------------------------------------------

variable "kinesis_streams" {
  description = "Map of Kinesis Data Stream definitions."
  type = map(object({
    shard_count      = optional(number, null) # null => ON_DEMAND mode
    on_demand        = optional(bool, false)
    retention_period = optional(number, 24) # hours; 24–8760
    shard_level_metrics = optional(list(string), [
      "IncomingBytes",
      "IncomingRecords",
      "OutgoingBytes",
      "OutgoingRecords",
      "WriteProvisionedThroughputExceeded",
      "ReadProvisionedThroughputExceeded",
      "IteratorAgeMilliseconds",
    ])
    encryption_type           = optional(string, "KMS")
    kms_key_id                = optional(string, "alias/aws/kinesis")
    enforce_consumer_deletion = optional(bool, false)
    tags                      = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Enhanced Fan-Out Consumers
# ---------------------------------------------------------------------------

variable "stream_consumers" {
  description = "Map of enhanced fan-out consumer definitions. Key is consumer name."
  type = map(object({
    stream_key    = string # key in var.kinesis_streams
    consumer_name = optional(string, null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Kinesis Firehose Delivery Streams
# ---------------------------------------------------------------------------

variable "firehose_streams" {
  description = "Map of Kinesis Firehose delivery stream definitions."
  type = map(object({
    source_stream_key = optional(string, null) # key in kinesis_streams; null = direct PUT
    destination       = string                 # "s3","redshift","opensearch","splunk","http_endpoint"

    s3_config = optional(object({
      bucket_arn            = string
      prefix                = optional(string, "data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/")
      error_output_prefix   = optional(string, "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/")
      buffering_size        = optional(number, 64)  # MB
      buffering_interval    = optional(number, 300) # seconds
      compression_format    = optional(string, "GZIP")
      kms_key_arn           = optional(string, null)
      lambda_processor_arn  = optional(string, null)
      parquet_conversion    = optional(bool, false)
      glue_database         = optional(string, null)
      glue_table            = optional(string, null)
      dynamic_partitioning  = optional(bool, false)
      cloudwatch_log_group  = optional(string, null)
      cloudwatch_log_stream = optional(string, null)
    }), null)

    redshift_config = optional(object({
      cluster_jdbcurl = string
      username        = string
      password        = string
      data_table_name = string
      copy_options    = optional(string, null)
      s3_backup_mode  = optional(string, "FailedDocumentsOnly")
      s3_bucket_arn   = string
      s3_prefix       = optional(string, "redshift-backup/")
    }), null)

    opensearch_config = optional(object({
      domain_arn         = string
      index_name         = string
      type_name          = optional(string, null)
      buffering_size     = optional(number, 5)
      buffering_interval = optional(number, 300)
      s3_bucket_arn      = string
      s3_prefix          = optional(string, "opensearch-backup/")
    }), null)

    splunk_config = optional(object({
      hec_endpoint               = string
      hec_token                  = string
      hec_endpoint_type          = optional(string, "Raw")
      hec_acknowledgment_timeout = optional(number, 600)
      s3_bucket_arn              = string
      s3_prefix                  = optional(string, "splunk-backup/")
    }), null)

    http_endpoint_config = optional(object({
      url                = string
      name               = optional(string, "HTTP Endpoint")
      access_key         = optional(string, null)
      buffering_size     = optional(number, 5)
      buffering_interval = optional(number, 300)
      s3_bucket_arn      = string
      s3_prefix          = optional(string, "http-backup/")
    }), null)

    server_side_encryption = optional(object({
      enabled  = optional(bool, true)
      key_type = optional(string, "CUSTOMER_MANAGED_CMK")
      key_arn  = optional(string, null)
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Kinesis Data Analytics v2 (Flink)
# ---------------------------------------------------------------------------

variable "analytics_applications" {
  description = "Map of Kinesis Data Analytics v2 (Flink) application definitions."
  type = map(object({
    runtime_environment    = optional(string, "FLINK-1_18")
    service_execution_role = optional(string, null) # null = auto-create
    description            = optional(string, null)

    code_s3_bucket = string
    code_s3_key    = string

    parallelism                   = optional(number, 1)
    parallelism_per_kpu           = optional(number, 1)
    auto_scaling_enabled          = optional(bool, true)
    checkpoint_enabled            = optional(bool, true)
    checkpoint_interval           = optional(number, 60000) # ms
    min_pause_between_checkpoints = optional(number, 5000)  # ms
    log_level                     = optional(string, "INFO")
    metrics_level                 = optional(string, "APPLICATION")

    environment_properties = optional(map(string), {})

    vpc_subnet_ids         = optional(list(string), [])
    vpc_security_group_ids = optional(list(string), [])

    cloudwatch_log_stream_arn = optional(string, null)

    start_application = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

variable "create_producer_role" {
  description = "Whether to create the shared Kinesis producer IAM role."
  type        = bool
  default     = true
}

variable "create_consumer_role" {
  description = "Whether to create the shared Kinesis consumer IAM role."
  type        = bool
  default     = true
}

variable "create_firehose_role" {
  description = "Whether to create the Firehose delivery IAM role."
  type        = bool
  default     = true
}

variable "producer_role_name" {
  description = "Override name for the producer IAM role."
  type        = string
  default     = null
}

variable "consumer_role_name" {
  description = "Override name for the consumer IAM role."
  type        = string
  default     = null
}

variable "firehose_role_name" {
  description = "Override name for the Firehose IAM role."
  type        = string
  default     = null
}

variable "analytics_role_name" {
  description = "Override name for the auto-created Analytics IAM role."
  type        = string
  default     = null
}

variable "lambda_transform_role_name" {
  description = "Override name for the Lambda transformation IAM role."
  type        = string
  default     = null
}

variable "create_lambda_transform_role" {
  description = "Whether to create a Lambda transformation role."
  type        = bool
  default     = false
}

variable "producer_additional_stream_arns" {
  description = "Extra stream ARNs to grant producer permissions on."
  type        = list(string)
  default     = []
}

variable "consumer_additional_stream_arns" {
  description = "Extra stream ARNs to grant consumer permissions on."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# CloudWatch Alarms
# ---------------------------------------------------------------------------

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications. Required when create_alarms = true."
  type        = string
  default     = null
}

variable "iterator_age_threshold_ms" {
  description = "Milliseconds threshold for GetRecords.IteratorAgeMilliseconds alarm."
  type        = number
  default     = 60000 # 1 minute
}

variable "put_records_failed_threshold" {
  description = "Count threshold for PutRecords.FailedRecords alarm."
  type        = number
  default     = 0
}

variable "firehose_freshness_threshold_seconds" {
  description = "Seconds threshold for Firehose DeliveryToS3.DataFreshness alarm."
  type        = number
  default     = 900 # 15 minutes
}

variable "firehose_success_threshold" {
  description = "Minimum successful delivery ratio for Firehose (0–1)."
  type        = number
  default     = 0.99
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for all alarms."
  type        = number
  default     = 2
}

variable "alarm_period_seconds" {
  description = "CloudWatch alarm evaluation period in seconds."
  type        = number
  default     = 300
}
