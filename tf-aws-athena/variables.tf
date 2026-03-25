variable "name_prefix" {
  description = "Prefix applied to all named resources created by this module."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Default tags merged into every taggable resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Workgroups
# ---------------------------------------------------------------------------
variable "workgroups" {
  description = "Map of Athena workgroup definitions."
  type = map(object({
    description                        = optional(string, null)
    state                              = optional(string, "ENABLED")
    enforce_workgroup_configuration    = optional(bool, true)
    publish_cloudwatch_metrics_enabled = optional(bool, true)
    bytes_scanned_cutoff_per_query     = optional(number, null)
    requester_pays_enabled             = optional(bool, false)
    engine_version                     = optional(string, "AUTO")
    force_destroy                      = optional(bool, false)

    result_configuration = optional(object({
      output_location       = string
      encryption_type       = optional(string, "SSE_S3")
      kms_key_arn           = optional(string, null)
      expected_bucket_owner = optional(string, null)
      s3_acl_option         = optional(string, null)
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Databases
# ---------------------------------------------------------------------------
variable "databases" {
  description = "Map of Glue catalog databases used by Athena."
  type = map(object({
    bucket                = string
    comment               = optional(string, null)
    encryption_type       = optional(string, "SSE_S3")
    kms_key_arn           = optional(string, null)
    expected_bucket_owner = optional(string, null)
    force_destroy         = optional(bool, false)
    properties            = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Named queries
# ---------------------------------------------------------------------------
variable "named_queries" {
  description = "Map of Athena saved named queries."
  type = map(object({
    name        = string
    description = optional(string, null)
    database    = string
    workgroup   = optional(string, "primary")
    query       = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Data catalogs
# ---------------------------------------------------------------------------
variable "data_catalogs" {
  description = "Map of federated Athena data catalogs (LAMBDA, GLUE, HIVE)."
  type = map(object({
    type        = string
    description = optional(string, null)
    parameters  = map(string)
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Prepared statements
# ---------------------------------------------------------------------------
variable "prepared_statements" {
  description = "Map of Athena prepared statements for parameterized queries."
  type = map(object({
    workgroup_name  = string
    description     = optional(string, null)
    query_statement = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Capacity reservations
# ---------------------------------------------------------------------------
variable "capacity_reservations" {
  description = "Map of Athena provisioned capacity reservations."
  type = map(object({
    target_dpus           = number
    workgroup_assignments = optional(list(string), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# IAM supporting variables
# ---------------------------------------------------------------------------
variable "results_bucket_arns" {
  description = "S3 bucket ARNs where Athena writes query results."
  type        = list(string)
  default     = []
}

variable "data_lake_bucket_arns" {
  description = "S3 bucket ARNs that Athena reads data from (data lake)."
  type        = list(string)
  default     = []
}

variable "results_kms_key_arn" {
  description = "KMS key ARN used to encrypt Athena query results."
  type        = string
  default     = null
}
