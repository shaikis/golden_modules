# ---------------------------------------------------------------------------
# Feature gates
# ---------------------------------------------------------------------------

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for MSK clusters."
  type        = bool
  default     = false
}

variable "create_serverless_clusters" {
  description = "Whether to create MSK Serverless clusters."
  type        = bool
  default     = false
}

variable "create_vpc_connections" {
  description = "Whether to create MSK VPC connections for cross-account access."
  type        = bool
  default     = false
}

variable "create_scram_auth" {
  description = "Whether to create SCRAM secret associations for MSK clusters."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Whether to create IAM producer and consumer roles for MSK."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO foundational resources
# ---------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "ARN of an existing KMS key (from tf-aws-kms) for MSK encryption at rest. If null, AWS-managed key is used."
  type        = string
  default     = null
}

variable "role_arn" {
  description = "ARN of an existing IAM role (from tf-aws-iam) to attach policies to instead of creating new roles."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to send CloudWatch alarm notifications to."
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
# MSK Provisioned clusters
# ---------------------------------------------------------------------------

variable "clusters" {
  description = "Map of MSK provisioned cluster configurations."
  type = map(object({
    kafka_version          = optional(string, "3.5.1")
    number_of_broker_nodes = optional(number, 3)
    instance_type          = optional(string, "kafka.m5.large")
    client_subnets         = list(string)
    security_group_ids     = list(string)
    ebs_volume_size        = optional(number, 100)
    # Provisioned throughput
    provisioned_throughput_enabled     = optional(bool, false)
    provisioned_throughput_volume_mbps = optional(number, 250)
    # Encryption
    encryption_in_transit = optional(string, "TLS")
    in_cluster_encryption = optional(bool, true)
    # Authentication
    enable_sasl_scram = optional(bool, false)
    enable_sasl_iam   = optional(bool, true)
    # TLS auth
    certificate_authority_arns = optional(list(string), [])
    unauthenticated            = optional(bool, false)
    # Monitoring
    enhanced_monitoring = optional(string, "PER_BROKER")
    # Prometheus
    jmx_exporter_enabled  = optional(bool, false)
    node_exporter_enabled = optional(bool, false)
    # Tiered / local storage
    tiered_storage_enabled = optional(bool, false)
    storage_mode           = optional(string, "LOCAL")
    # Logging
    cloudwatch_logs_enabled  = optional(bool, true)
    log_group                = optional(string, null)
    firehose_logs_enabled    = optional(bool, false)
    firehose_delivery_stream = optional(string, null)
    s3_logs_enabled          = optional(bool, false)
    s3_logs_bucket           = optional(string, null)
    s3_logs_prefix           = optional(string, null)
    # MSK Configuration
    configuration_key = optional(string, null)
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# MSK Serverless clusters
# ---------------------------------------------------------------------------

variable "serverless_clusters" {
  description = "Map of MSK Serverless cluster configurations."
  type = map(object({
    cluster_name       = optional(string, null)
    subnet_ids         = list(string)
    security_group_ids = list(string)
    tags               = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# MSK Configurations (Kafka broker config)
# ---------------------------------------------------------------------------

variable "configurations" {
  description = "Map of MSK cluster configurations (Kafka broker properties)."
  type = map(object({
    name              = string
    description       = optional(string, "")
    kafka_versions    = optional(list(string), ["3.5.1"])
    server_properties = optional(string, null) # Raw key=value overrides; module merges with defaults
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# SCRAM secret associations
# ---------------------------------------------------------------------------

variable "scram_associations" {
  description = "Map of SCRAM secret associations. Key is the cluster key from var.clusters."
  type = map(object({
    cluster_key     = string
    secret_arn_list = list(string)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# VPC connections
# ---------------------------------------------------------------------------

variable "vpc_connections" {
  description = "Map of MSK VPC connections for cross-account access."
  type = map(object({
    cluster_key        = string
    target_cluster_arn = optional(string, null) # Override cluster ARN lookup
    client_subnets     = list(string)
    security_groups    = list(string)
    vpc_id             = string
    authentication     = optional(string, "SASL_IAM") # SASL_IAM | SASL_SCRAM | TLS
    tags               = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# IAM role settings
# ---------------------------------------------------------------------------

variable "iam_role_name_prefix" {
  description = "Prefix for IAM role names created by this module."
  type        = string
  default     = "msk"
}

variable "producer_topic_arns" {
  description = "List of MSK topic ARNs the producer role is allowed to write to."
  type        = list(string)
  default     = ["*"]
}

variable "consumer_topic_arns" {
  description = "List of MSK topic ARNs the consumer role is allowed to read from."
  type        = list(string)
  default     = ["*"]
}

variable "consumer_group_arns" {
  description = "List of MSK consumer group ARNs the consumer role is allowed to use."
  type        = list(string)
  default     = ["*"]
}

variable "iam_producer_assume_role_principals" {
  description = "List of IAM principal ARNs that can assume the producer role."
  type        = list(string)
  default     = []
}

variable "iam_consumer_assume_role_principals" {
  description = "List of IAM principal ARNs that can assume the consumer role."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Alarm thresholds
# ---------------------------------------------------------------------------

variable "alarm_disk_used_percent_threshold" {
  description = "Threshold percentage for KafkaAppLogsDiskUsed alarm."
  type        = number
  default     = 70
}

variable "alarm_memory_used_percent_threshold" {
  description = "Threshold percentage for MemoryUsed alarm."
  type        = number
  default     = 80
}

variable "alarm_cpu_user_threshold" {
  description = "Threshold percentage for CPUUser alarm."
  type        = number
  default     = 60
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarms."
  type        = number
  default     = 3
}

variable "alarm_period_seconds" {
  description = "Period in seconds for CloudWatch alarm metrics."
  type        = number
  default     = 300
}

# ---------------------------------------------------------------------------
# MSK Replicators (cross-region topic replication)
# ---------------------------------------------------------------------------

variable "replicators" {
  description = <<-EOT
    Map of MSK Replicator configurations for cross-region Kafka topic replication.
    Each replicator continuously mirrors topics from a source MSK cluster to a target cluster.

    Key fields:
      source_cluster_arn          - ARN of the source MSK cluster (this region)
      target_cluster_arn          - ARN of the target MSK cluster (peer region)
      source_subnet_ids           - Subnets in the source VPC for replicator ENIs
      target_subnet_ids           - Subnets in the target VPC for replicator ENIs
      source_security_group_ids   - Security groups for source VPC connectivity
      target_security_group_ids   - Security groups for target VPC connectivity
      service_execution_role_arn  - BYO IAM role; auto-created when null
      target_compression_type     - NONE | GZIP | SNAPPY | LZ4 | ZSTD
      topic_replication:
        topics_to_replicate              - List of topic name patterns (supports wildcards)
        topics_to_exclude                - List of topic name patterns to skip
        detect_and_copy_new_topics       - Auto-replicate newly created topics
        copy_access_control_lists_for_topics - Mirror topic ACLs
        copy_topic_configurations        - Mirror topic config (retention, partitions)
        starting_position_type           - LATEST | EARLIEST
      consumer_group_replication (optional):
        consumer_groups_to_replicate          - Consumer group patterns to replicate
        consumer_groups_to_exclude            - Consumer group patterns to skip
        detect_and_copy_new_consumer_groups   - Auto-replicate new consumer groups
        synchronise_consumer_group_offsets    - Keep consumer offsets in sync
  EOT
  type = map(object({
    description                = optional(string, "")
    source_cluster_arn         = string
    target_cluster_arn         = string
    source_subnet_ids          = list(string)
    target_subnet_ids          = list(string)
    source_security_group_ids  = list(string)
    target_security_group_ids  = list(string)
    service_execution_role_arn = optional(string, null)
    target_compression_type    = optional(string, "NONE")
    tags                       = optional(map(string), {})

    topic_replication = object({
      topics_to_replicate                  = optional(list(string), [".*"])
      topics_to_exclude                    = optional(list(string), [".*[\\-\\.]internal", ".*\\.replica", "__.*"])
      detect_and_copy_new_topics           = optional(bool, true)
      copy_access_control_lists_for_topics = optional(bool, true)
      copy_topic_configurations            = optional(bool, true)
      starting_position_type               = optional(string, "LATEST")
    })

    consumer_group_replication = optional(object({
      consumer_groups_to_replicate        = optional(list(string), [".*"])
      consumer_groups_to_exclude          = optional(list(string), [])
      detect_and_copy_new_consumer_groups = optional(bool, true)
      synchronise_consumer_group_offsets  = optional(bool, true)
    }), null)
  }))
  default = {}
}
