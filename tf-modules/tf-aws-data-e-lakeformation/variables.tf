variable "create_permissions" {
  description = "Whether to create Lake Formation permissions."
  type        = bool
  default     = false
}

variable "create_lf_tags" {
  description = "Whether to create LF-Tags for attribute-based access control."
  type        = bool
  default     = false
}

variable "create_data_filters" {
  description = "Whether to create data cell filters for row/column-level security."
  type        = bool
  default     = false
}

variable "create_governed_tables" {
  description = "Whether to create Lake Formation governed table LF-tag assignments."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Whether to create an IAM role for Lake Formation service access."
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Existing IAM role ARN to use instead of creating one (from tf-aws-iam)."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting Lake Formation resources (from tf-aws-kms)."
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name for the Lake Formation IAM role. Defaults to lakeformation-service-role."
  type        = string
  default     = "lakeformation-service-role"
}

variable "iam_role_path" {
  description = "IAM path for the Lake Formation service role."
  type        = string
  default     = "/"
}

variable "iam_role_tags" {
  description = "Additional tags for the IAM role."
  type        = map(string)
  default     = {}
}

variable "data_lake_admins" {
  description = "IAM ARNs of Lake Formation administrators."
  type        = list(string)
  default     = []
}

variable "readonly_admins" {
  description = "IAM ARNs of read-only Lake Formation administrators."
  type        = list(string)
  default     = []
}

variable "allow_external_data_filtering" {
  description = "Whether to allow external data filtering (Amazon EMR on EC2 with Lake Formation)."
  type        = bool
  default     = false
}

variable "external_data_filtering_allow_list" {
  description = "List of AWS account IDs allowed for external data filtering."
  type        = list(string)
  default     = []
}

variable "authorized_session_tag_value_list" {
  description = "Lake Formation session tag values authorized for data access."
  type        = list(string)
  default     = []
}

variable "create_database_default_permissions" {
  description = "Default permissions granted to principals when a new database is created."
  type = list(object({
    principal   = string
    permissions = list(string)
  }))
  default = []
}

variable "create_table_default_permissions" {
  description = "Default permissions granted to principals when a new table is created."
  type = list(object({
    principal   = string
    permissions = list(string)
  }))
  default = []
}

variable "data_lake_locations" {
  description = "S3 locations to register as Lake Formation data lake resources."
  type = map(object({
    s3_arn                  = string
    use_service_linked_role = optional(bool, true)
    role_arn                = optional(string, null)
    hybrid_access_enabled   = optional(bool, false)
    with_federation         = optional(bool, false)
  }))
  default = {}
}

variable "lf_tags" {
  description = "Map of LF-Tags to create for attribute-based access control."
  type = map(object({
    values = list(string)
  }))
  default = {}
}

variable "lf_tag_policies" {
  description = "Map of LF-Tag policies to assign permissions to resources matching tag expressions."
  type = map(object({
    principal                     = string
    resource_type                 = string
    permissions                   = list(string)
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string, null)
    expression = list(object({
      key    = string
      values = list(string)
    }))
  }))
  default = {}
}

variable "permissions" {
  description = "Map of Lake Formation permissions to grant on databases, tables, or data locations."
  type = map(object({
    principal                     = string
    permissions                   = list(string)
    permissions_with_grant_option = optional(list(string), [])
    catalog_id                    = optional(string, null)

    database = optional(object({
      name       = string
      catalog_id = optional(string, null)
    }), null)

    table = optional(object({
      database_name = string
      name          = optional(string, null)
      wildcard      = optional(bool, false)
      catalog_id    = optional(string, null)
    }), null)

    table_with_columns = optional(object({
      database_name         = string
      name                  = string
      column_names          = optional(list(string), [])
      excluded_column_names = optional(list(string), [])
      wildcard              = optional(bool, false)
      catalog_id            = optional(string, null)
    }), null)

    data_location = optional(object({
      arn        = string
      catalog_id = optional(string, null)
    }), null)

    lf_tag = optional(object({
      key    = string
      values = list(string)
    }), null)

    lf_tag_policy = optional(object({
      resource_type = string
      catalog_id    = optional(string, null)
      expression = list(object({
        key    = string
        values = list(string)
      }))
    }), null)
  }))
  default = {}
}

variable "data_cell_filters" {
  description = "Map of data cell filters for row-level and column-level security."
  type = map(object({
    database_name         = string
    table_name            = string
    name                  = string
    table_catalog_id      = optional(string, null)
    row_filter_expression = optional(string, null)
    column_names          = optional(list(string), [])
    excluded_column_names = optional(list(string), [])
  }))
  default = {}
}

variable "resource_lf_tags" {
  description = "Map of LF-Tag assignments to databases and tables."
  type = map(object({
    catalog_id = optional(string, null)
    database = optional(object({
      name       = string
      catalog_id = optional(string, null)
    }), null)
    table = optional(object({
      database_name = string
      name          = optional(string, null)
      wildcard      = optional(bool, false)
      catalog_id    = optional(string, null)
    }), null)
    table_with_columns = optional(object({
      database_name         = string
      name                  = string
      column_names          = optional(list(string), [])
      excluded_column_names = optional(list(string), [])
      wildcard              = optional(bool, false)
      catalog_id            = optional(string, null)
    }), null)
    lf_tags = list(object({
      key        = string
      value      = string
      catalog_id = optional(string, null)
    }))
  }))
  default = {}
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs the Lake Formation role needs access to (used when create_iam_role = true)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}
