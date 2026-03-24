# ── Feature Gates ─────────────────────────────────────────────────────────────
# Only resources you opt into will be created.
# Minimum setup: define jobs {} and the module creates Glue jobs + IAM role.

variable "create_catalog_databases" {
  description = "Set true to create Glue Data Catalog databases."
  type        = bool
  default     = false
}

variable "create_crawlers" {
  description = "Set true to create Glue crawlers."
  type        = bool
  default     = false
}

variable "create_triggers" {
  description = "Set true to create Glue triggers (scheduled/conditional/on-demand)."
  type        = bool
  default     = false
}

variable "create_workflows" {
  description = "Set true to create Glue workflows."
  type        = bool
  default     = false
}

variable "create_connections" {
  description = "Set true to create Glue connections (JDBC, Kafka, etc.)."
  type        = bool
  default     = false
}

variable "create_schema_registries" {
  description = "Set true to create Glue schema registries and schemas."
  type        = bool
  default     = false
}

variable "create_security_configurations" {
  description = "Set true to create Glue security configurations (KMS encryption)."
  type        = bool
  default     = false
}

variable "create_catalog_encryption" {
  description = "Set true to enable KMS encryption for the Glue Data Catalog."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Set true to auto-create the Glue service IAM role. Set false to pass your own role_arn."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Global
# ---------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix added to all resource names to ensure uniqueness."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Default tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Glue Data Catalog — databases
# ---------------------------------------------------------------------------

variable "catalog_databases" {
  description = "Map of Glue catalog databases to create."
  type = map(object({
    description  = optional(string, null)
    location_uri = optional(string, null)
    parameters   = optional(map(string), {})
    target_database = optional(object({
      catalog_id    = string
      database_name = string
      region        = optional(string, null)
    }), null)
    create_table_default_permissions = optional(list(object({
      permissions = list(string)
      principal = object({
        data_lake_principal_identifier = optional(string, null)
      })
    })), null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Glue Data Catalog — tables
# ---------------------------------------------------------------------------

variable "catalog_tables" {
  description = "Map of Glue catalog tables. Key format: '<database_name>/<table_name>'."
  type = map(object({
    database_name = string
    description   = optional(string, null)
    table_type    = optional(string, "EXTERNAL_TABLE")
    owner         = optional(string, null)
    parameters    = optional(map(string), {})

    partition_keys = optional(list(object({
      name    = string
      type    = optional(string, "string")
      comment = optional(string, null)
    })), [])

    storage_descriptor = optional(object({
      location                  = optional(string, null)
      input_format              = optional(string, "org.apache.hadoop.mapred.TextInputFormat")
      output_format             = optional(string, "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat")
      compressed                = optional(bool, false)
      number_of_buckets         = optional(number, -1)
      stored_as_sub_directories = optional(bool, false)
      parameters                = optional(map(string), {})

      columns = optional(list(object({
        name       = string
        type       = string
        comment    = optional(string, null)
        parameters = optional(map(string), {})
      })), [])

      ser_de_info = optional(object({
        name                  = optional(string, null)
        serialization_library = optional(string, null)
        parameters            = optional(map(string), {})
      }), null)

      bucket_columns = optional(list(string), [])

      sort_columns = optional(list(object({
        column     = string
        sort_order = number
      })), [])

      skewed_info = optional(object({
        skewed_column_names               = optional(list(string), [])
        skewed_column_value_location_maps = optional(map(string), {})
        skewed_column_values              = optional(list(string), [])
      }), null)
    }), null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Glue Data Catalog encryption
# ---------------------------------------------------------------------------

variable "enable_catalog_encryption" {
  description = "Enable SSE-KMS encryption for the Glue Data Catalog."
  type        = bool
  default     = false
}

variable "catalog_encryption_kms_key_id" {
  description = "KMS key ID for Glue Data Catalog encryption."
  type        = string
  default     = null
}

variable "catalog_connection_password_encryption_kms_key_id" {
  description = "KMS key ID for encrypting connection passwords stored in the catalog."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Glue Crawlers
# ---------------------------------------------------------------------------

variable "crawlers" {
  description = "Map of Glue crawlers to create."
  type = map(object({
    database_name          = string
    role_arn               = optional(string, null)
    schedule               = optional(string, null)
    description            = optional(string, null)
    classifiers            = optional(list(string), [])
    security_configuration = optional(string, null)
    table_prefix           = optional(string, null)
    configuration          = optional(string, null)

    s3_targets = optional(list(object({
      path            = string
      exclusions      = optional(list(string), [])
      connection_name = optional(string, null)
      sample_size     = optional(number, null)
    })), [])

    jdbc_targets = optional(list(object({
      connection_name = string
      path            = string
      exclusions      = optional(list(string), [])
    })), [])

    catalog_targets = optional(list(object({
      database_name = string
      tables        = list(string)
    })), [])

    dynamodb_targets = optional(list(object({
      path      = string
      scan_all  = optional(bool, false)
      scan_rate = optional(number, null)
    })), [])

    kafka_targets = optional(list(object({
      connection_name  = string
      topic_name       = string
      starting_offsets = optional(string, "earliest")
    })), [])

    delta_target = optional(list(object({
      delta_tables    = list(string)
      write_manifest  = optional(bool, false)
      connection_name = optional(string, null)
    })), [])

    schema_change_policy = optional(object({
      delete_behavior = optional(string, "LOG")
      update_behavior = optional(string, "UPDATE_IN_DATABASE")
    }), {})

    recrawl_policy = optional(string, "CRAWL_NEW_FOLDERS_ONLY")
    lineage        = optional(bool, false)

    lake_formation_configuration = optional(object({
      account_id                     = optional(string, null)
      use_lake_formation_credentials = optional(bool, false)
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Glue Jobs
# ---------------------------------------------------------------------------

variable "jobs" {
  description = "Map of Glue ETL jobs to create."
  type = map(object({
    description               = optional(string, null)
    role_arn                  = optional(string, null)
    script_location           = string
    glue_version              = optional(string, "4.0")
    language                  = optional(string, "python")
    job_type                  = optional(string, "glueetl")
    python_version            = optional(string, "3")
    worker_type               = optional(string, "G.1X")
    number_of_workers         = optional(number, 2)
    max_retries               = optional(number, 1)
    timeout                   = optional(number, 2880)
    execution_class           = optional(string, "STANDARD")
    max_concurrent_runs       = optional(number, 1)
    notify_delay_after        = optional(number, null)
    connections               = optional(list(string), [])
    security_configuration    = optional(string, null)
    bookmark_option           = optional(string, "job-bookmark-enable")
    default_arguments         = optional(map(string), {})
    non_overridable_arguments = optional(map(string), {})
    tags                      = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Glue Workflows
# ---------------------------------------------------------------------------

variable "workflows" {
  description = "Map of Glue workflows to create."
  type = map(object({
    description            = optional(string, null)
    default_run_properties = optional(map(string), {})
    max_concurrent_runs    = optional(number, 1)
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Glue Triggers
# ---------------------------------------------------------------------------

variable "triggers" {
  description = "Map of Glue triggers to create."
  type = map(object({
    type              = string
    description       = optional(string, null)
    workflow_name     = optional(string, null)
    schedule          = optional(string, null)
    enabled           = optional(bool, true)
    start_on_creation = optional(bool, true)

    actions = list(object({
      job_name               = optional(string, null)
      crawler_name           = optional(string, null)
      arguments              = optional(map(string), {})
      timeout                = optional(number, null)
      security_configuration = optional(string, null)
      notification_property = optional(object({
        notify_delay_after = optional(number, null)
      }), null)
    }))

    predicate = optional(object({
      logical = optional(string, "AND")
      conditions = list(object({
        job_name         = optional(string, null)
        crawler_name     = optional(string, null)
        state            = optional(string, null)
        crawl_state      = optional(string, null)
        logical_operator = optional(string, "EQUALS")
      }))
    }), null)

    event_batching_condition = optional(object({
      batch_size   = number
      batch_window = optional(number, null)
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Glue Connections
# ---------------------------------------------------------------------------

variable "connections" {
  description = "Map of Glue connections to create."
  type = map(object({
    connection_type       = optional(string, "JDBC")
    description           = optional(string, null)
    connection_properties = map(string)
    subnet_id             = optional(string, null)
    security_group_ids    = optional(list(string), [])
    availability_zone     = optional(string, null)
    match_criteria        = optional(list(string), [])
    tags                  = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Schema Registry
# ---------------------------------------------------------------------------

variable "schema_registries" {
  description = "Map of Glue Schema Registries and their schemas."
  type = map(object({
    description = optional(string, null)
    schemas = optional(map(object({
      schema_name       = string
      description       = optional(string, null)
      data_format       = string
      compatibility     = optional(string, "BACKWARD")
      schema_definition = string
      tags              = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Security Configurations
# ---------------------------------------------------------------------------

variable "security_configurations" {
  description = "Map of Glue security configurations."
  type = map(object({
    s3_encryption_mode         = optional(string, "SSE-KMS")
    s3_kms_key_arn             = optional(string, null)
    cloudwatch_encryption_mode = optional(string, "SSE-KMS")
    cloudwatch_kms_key_arn     = optional(string, null)
    bookmark_encryption_mode   = optional(string, "CSE-KMS")
    bookmark_kms_key_arn       = optional(string, null)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

variable "create_service_role" {
  description = "Whether to create a shared Glue service IAM role."
  type        = bool
  default     = true
}

variable "service_role_name" {
  description = "Name of the Glue service IAM role. Defaults to '<name_prefix>glue-service-role'."
  type        = string
  default     = null
}

variable "data_lake_bucket_arns" {
  description = "List of S3 bucket ARNs the Glue role can read/write (data lake buckets)."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "List of KMS key ARNs the Glue role needs decrypt/generate-data-key access to."
  type        = list(string)
  default     = []
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the Glue service role."
  type        = list(string)
  default     = []
}

variable "enable_secrets_manager_access" {
  description = "Grant the Glue role read access to all Secrets Manager secrets."
  type        = bool
  default     = false
}
