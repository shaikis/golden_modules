variable "primary_region" {
  type    = string
  default = "us-east-1"
}
variable "dr_region" {
  type    = string
  default = "us-west-2"
}
variable "name" {
  type    = string
  default = "myapp"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "project" {
  type    = string
  default = "myproject"
}
variable "owner" {
  type    = string
  default = "platform"
}
variable "cost_center" {
  type    = string
  default = "shared"
}
variable "tags" {
  type    = map(string)
  default = {
} }

# SQL Server edition — choose one:
#   sqlserver-ee  : Enterprise Edition (BYOL or LI)
#   sqlserver-se  : Standard Edition (BYOL or LI)
#   sqlserver-ex  : Express Edition (free, max 1 vCPU / 1 GiB RAM)
#   sqlserver-web : Web Edition (LI only)
variable "sqlserver_edition" {
  type    = string
  default = "sqlserver-se"
}
variable "engine_version" {
  type    = string
  default = "15.00"
}     # SQL Server 2019
variable "instance_class" {
  type    = string
  default = "db.m5.xlarge"
}   # min for SE/EE

# License model:
#   license-included      : AWS provides the SQL Server license
#   bring-your-own-license : use your own SA/Volume License (EE and SE only)
variable "license_model" {
  type    = string
  default = "license-included"
}
variable "timezone" {
  type    = string
  default = "UTC"
}
variable "parameter_group_family" {
  type    = string
  default = "sqlserver-se-15.0"
}

variable "username" {
  type    = string
  default = "admin"
}

variable "allocated_storage" {
  type    = number
  default = 200
}   # min 200 GiB for SQL Server
variable "max_allocated_storage" {
  type    = number
  default = 1000
}
variable "storage_type" {
  type    = string
  default = "gp3"
}
variable "iops" {
  type    = number
  default = null
}

variable "primary_kms_key_arn" {
  type    = string
  default = null
}
variable "dr_kms_key_arn" {
  type    = string
  default = null
}

variable "primary_subnet_group_name" {
  type    = string
  default = ""
}
variable "primary_security_group_ids" {
  type    = list(string)
  default = []
}
variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "backup_window" {
  type    = string
  default = "02:00-03:00"
}
variable "maintenance_window" {
  type    = string
  default = "Mon:03:00-Mon:04:00"
}
variable "skip_final_snapshot" {
  type    = bool
  default = false
}
variable "final_snapshot_identifier_prefix" {
  type    = string
  default = "final"
}
variable "deletion_protection" {
  type    = bool
  default = true
}

variable "monitoring_interval" {
  type    = number
  default = 60
}
variable "performance_insights_enabled" {
  type    = bool
  default = true
}
variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["agent", "error"]
}

variable "create_parameter_group" {
  type    = bool
  default = false
}
variable "parameters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Option Group
# ---------------------------------------------------------------------------
variable "create_option_group" {
  type    = bool
  default = false
}
variable "option_group_major_engine_version" {
  type    = string
  default = "15.00"   # SQL Server 2019; use "14.00" for 2017, "16.00" for 2022
}
variable "options" {
  description = "SQL Server option group options. See module variable docs for full schema."
  type = list(object({
    option_name                    = string
    port                           = optional(number)
    db_security_group_memberships  = optional(list(string))
    vpc_security_group_memberships = optional(list(string))
    option_settings = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = [
    # Enable SQL Server Agent (scheduled jobs, maintenance plans)
    { option_name = "SQLSERVER_AGENT" },
  ]
}

# ---------------------------------------------------------------------------
# Active Directory / Domain Join
# ---------------------------------------------------------------------------
variable "domain" {
  description = "AWS Managed Microsoft AD directory ID (e.g. d-1234567890). Leave null to skip domain join."
  type        = string
  default     = null
}
variable "create_domain_iam_role" {
  type    = bool
  default = false
}
variable "domain_iam_role_name" {
  description = "BYO IAM role name for domain join. Used only when create_domain_iam_role = false."
  type        = string
  default     = null
}
variable "domain_fqdn" {
  description = "Self-managed AD FQDN (e.g. corp.example.com). Mutually exclusive with domain."
  type        = string
  default     = null
}
variable "domain_dns_ips" {
  type    = list(string)
  default = null
}
variable "domain_ou" {
  type    = string
  default = null
}
variable "domain_auth_secret_arn" {
  description = "Secrets Manager ARN for the AD domain-join service account (self-managed AD only)."
  type        = string
  default     = null
}

# NOTE: SQL Server does NOT support cross-region read replicas.
# Only automated backup replication is available.
variable "enable_automated_backup_replication" {
  type    = bool
  default = false
}
variable "automated_backup_replication_retention_period" {
  type    = number
  default = 7
}
variable "automated_backup_replication_kms_key_arn" {
  type    = string
  default = null
}
