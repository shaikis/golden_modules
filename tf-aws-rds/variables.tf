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

# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------
variable "engine" {
  description = "Database engine: mysql, postgres, mariadb, oracle-ee, sqlserver-ee, etc."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version. Leave empty to use latest."
  type        = string
  default     = "15.5"
}

variable "instance_class" {
  description = "DB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "license_model" {
  description = "License model. Required for Oracle/SQL Server."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = null
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password. Use manage_master_user_password=true to let AWS manage it."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password in Secrets Manager."
  type        = bool
  default     = true
}

variable "master_user_secret_kms_key_id" {
  description = "KMS key for master password secret (if manage_master_user_password=true)."
  type        = string
  default     = null
}

variable "port" {
  description = "Database port. Defaults to engine-specific port."
  type        = number
  default     = null
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max storage for autoscaling (0 = disabled)."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "gp2, gp3, io1."
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS for io1/io2/gp3. Required for io1/io2; optional for gp3."
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = <<-EOT
    Throughput in MB/s for gp3 storage. Valid range: 125–4000.
    Only applicable when storage_type = "gp3".
    Leave null to use the gp3 default (125 MB/s).
  EOT
  type        = number
  default     = null
}

variable "dedicated_log_volume" {
  description = <<-EOT
    Use a dedicated EBS volume for the database write-ahead log (WAL/redo log).
    Improves I/O performance for write-heavy workloads.
    Supported on io1 storage with db.m* and db.r* instance classes.
  EOT
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Encrypt the database storage."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "db_subnet_group_name" {
  description = "DB subnet group name. Required."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to associate."
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Allow public internet access."
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "AZ for single-AZ deployment."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# High Availability
# ---------------------------------------------------------------------------
variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
variable "backup_retention_period" {
  description = "Backup retention in days (0 = disabled)."
  type        = number
  default     = 14
}

variable "backup_window" {
  description = "Daily backup window (UTC). e.g. 03:00-04:00"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window. e.g. sun:05:00-sun:06:00"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier_prefix" {
  description = "Prefix for final snapshot identifier."
  type        = string
  default     = "final"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to DB snapshots."
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Delete automated backups on destroy."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Protection
# ---------------------------------------------------------------------------
variable "deletion_protection" {
  description = "Prevent deletion of the DB instance."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 = disabled). Valid: 0,1,5,10,15,30,60."
  type        = number
  default     = 60
}

variable "monitoring_role_arn" {
  description = "ARN of IAM role for enhanced monitoring."
  type        = string
  default     = null
}

variable "create_monitoring_role" {
  description = "Auto-create IAM role for enhanced monitoring."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days."
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "KMS key for Performance Insights."
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch."
  type        = list(string)
  default     = ["postgresql"]
}

# ---------------------------------------------------------------------------
# Parameter / Option Groups
# ---------------------------------------------------------------------------
variable "parameter_group_name" {
  description = "Parameter group name. Leave empty to use default."
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "BYO option group name. Ignored when create_option_group = true."
  type        = string
  default     = null
}

variable "create_option_group" {
  description = "Create a custom option group inside this module."
  type        = bool
  default     = false
}

variable "option_group_description" {
  description = "Description for the option group. Defaults to 'Option group for <name>'."
  type        = string
  default     = null
}

variable "option_group_engine_name" {
  description = <<-EOT
    Engine name for the option group. Must match the DB engine family.
    Examples: "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web",
              "mysql", "oracle-ee".
    Required when create_option_group = true.
  EOT
  type        = string
  default     = null
}

variable "option_group_major_engine_version" {
  description = <<-EOT
    Major engine version string for the option group.
    Examples: "15.00" (SQL Server 2019), "8.0" (MySQL 8.0), "19" (Oracle 19c).
    Required when create_option_group = true.
  EOT
  type        = string
  default     = null
}

variable "options" {
  description = <<-EOT
    List of option definitions for the option group.
    Each object supports:
      option_name                    - (required) name of the option
      port                           - (optional) port override
      db_security_group_memberships  - (optional) list of DB SG names
      vpc_security_group_memberships - (optional) list of VPC SG IDs
      option_settings                - (optional) list of { name, value } maps
    Common SQL Server options:
      SQLSERVER_AGENT           — enable SQL Server Agent
      TRANSPARENT_DATA_ENCRYPT  — Transparent Data Encryption (TDE)
      NATIVE_SRVR_BACKUPS       — Native Backup & Restore to S3
      SSRS                      — SQL Server Reporting Services
      SSAS                      — SQL Server Analysis Services
  EOT
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
  default = []
}

variable "parameters" {
  description = "Map of DB parameters to create a custom parameter group."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "create_parameter_group" {
  description = "Create a custom parameter group from the parameters list."
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g. postgres15)."
  type        = string
  default     = "postgres15"
}

# ---------------------------------------------------------------------------
# Read Replicas
# ---------------------------------------------------------------------------
variable "replicate_source_db" {
  description = "ARN of a source DB instance to create a read replica."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Cross-Region Automated Backup Replication (choice-based)
# ---------------------------------------------------------------------------
variable "enable_automated_backup_replication" {
  description = <<-EOT
    Enable automated backup replication to a secondary AWS region.
    When true, set automated_backup_replication_region and backup_retention_period >= 1.
    NOTE: The aws_db_instance_automated_backups_replication resource runs in the
    destination region. It is created directly in the cross_region example using
    provider = aws.dr alongside this module call.
  EOT
  type        = bool
  default     = false
}

variable "automated_backup_replication_region" {
  description = "Destination region for automated backup replication (e.g. 'us-west-2'). Used only in examples."
  type        = string
  default     = null
}

variable "automated_backup_replication_retention_period" {
  description = "Retention period (days) for replicated automated backups in the destination region."
  type        = number
  default     = 7
}

variable "automated_backup_replication_kms_key_arn" {
  description = "KMS key ARN in the destination region for encrypting replicated backups. Null = AWS-managed key."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Miscellaneous
# ---------------------------------------------------------------------------
variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}
variable "apply_immediately" {
  type    = bool
  default = false
}
variable "allow_major_version_upgrade" {
  type    = bool
  default = false
}
variable "ca_cert_identifier" {
  type    = string
  default = null
}
variable "character_set_name" {
  type    = string
  default = null
}
variable "timezone" {
  type    = string
  default = null
}
variable "network_type" {
  description = "Network type: IPV4 or DUAL (dual-stack IPv4+IPv6)."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# IAM Database Authentication
# ---------------------------------------------------------------------------
variable "iam_database_authentication_enabled" {
  description = <<-EOT
    Enable IAM-based authentication for the database.
    Supported engines: MySQL 5.6+, PostgreSQL 9.5+.
    When enabled, IAM users/roles can authenticate using an auth token
    instead of a password (aws rds generate-db-auth-token).
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Snapshot & Point-in-Time Restore
# ---------------------------------------------------------------------------
variable "snapshot_identifier" {
  description = <<-EOT
    Snapshot ID or ARN to restore from. When set, the instance is created
    from this snapshot and most storage/database settings are inherited from it.
    Useful for cloning production to staging or disaster recovery restores.
  EOT
  type        = string
  default     = null
}

variable "restore_to_point_in_time" {
  description = <<-EOT
    Restore the instance to a point in time from an existing instance.
    Provide one of:
      source_db_instance_identifier             — source instance ID (same account/region)
      source_db_instance_automated_backups_arn  — ARN of automated backup (cross-account/region)
      source_dbi_resource_id                    — resource ID of the source instance
    And either:
      restore_time          — UTC datetime string "2024-01-15T03:00:00Z"
      use_latest_restorable_time = true
  EOT
  type = object({
    restore_time                             = optional(string)
    source_db_instance_identifier            = optional(string)
    source_db_instance_automated_backups_arn = optional(string)
    source_dbi_resource_id                   = optional(string)
    use_latest_restorable_time               = optional(bool, false)
  })
  default = null
}

# ---------------------------------------------------------------------------
# S3 Import (MySQL bulk data load)
# ---------------------------------------------------------------------------
variable "s3_import" {
  description = <<-EOT
    Import MySQL data from a Percona XtraBackup stored in S3.
    Only supported for MySQL engine.
    Fields:
      bucket_name           — S3 bucket containing the backup
      bucket_prefix         — (optional) S3 key prefix
      ingestion_role        — ARN of IAM role with s3:GetObject on the bucket
      source_engine         — always "mysql"
      source_engine_version — e.g. "8.0"
  EOT
  type = object({
    bucket_name           = string
    bucket_prefix         = optional(string, "")
    ingestion_role        = string
    source_engine         = string
    source_engine_version = string
  })
  default = null
}

# ---------------------------------------------------------------------------
# Blue/Green Deployment (zero-downtime major version upgrades)
# ---------------------------------------------------------------------------
variable "blue_green_update" {
  description = <<-EOT
    Enable Blue/Green deployment for zero-downtime upgrades and schema changes.
    When enabled = true, RDS manages a staging (green) environment in sync
    with the production (blue) instance. Switch-over is triggered manually.
    Supported: MySQL 5.7/8.0, PostgreSQL 11+, MariaDB.
    Not supported: Oracle, SQL Server, Multi-AZ DB Clusters.
  EOT
  type = object({
    enabled = bool
  })
  default = null
}

# ---------------------------------------------------------------------------
# Oracle / SQL Server — additional engine-specific settings
# ---------------------------------------------------------------------------
variable "nchar_character_set_name" {
  description = <<-EOT
    National character set for the database.
    Oracle: "AL16UTF16" (default) or "UTF8".
    SQL Server: not applicable; use character_set_name instead.
    Can only be set at creation time — changes require a snapshot restore.
  EOT
  type        = string
  default     = null
}

variable "replica_mode" {
  description = <<-EOT
    Oracle read replica mode.
    "open-read-only" — replica is open for read-only queries (default).
    "mounted"        — replica is mounted but not open; required for some
                       Oracle Data Guard configurations.
    Only applicable when replicate_source_db is set and engine is oracle-*.
  EOT
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# RDS Custom (Bring Your Own OS / Oracle/SQL Server on custom hardware)
# ---------------------------------------------------------------------------
variable "custom_iam_instance_profile" {
  description = <<-EOT
    IAM instance profile ARN for RDS Custom instances.
    Only applicable for RDS Custom for Oracle or RDS Custom for SQL Server.
    The profile must have the AmazonRDSCustomInstanceProfileRolePolicy managed
    policy attached and the instance must use a Custom engine variant.
  EOT
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Identifier prefix (alternative to fixed identifier)
# ---------------------------------------------------------------------------
variable "identifier_prefix" {
  description = <<-EOT
    Prefix for an auto-generated unique identifier. Mutually exclusive with
    the default fixed identifier derived from name+environment. Useful for
    multi-instance deployments where each instance needs a unique name without
    manual coordination (e.g. blue/green standby instances).
  EOT
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Active Directory / Domain Join (SQL Server Windows Authentication)
# ---------------------------------------------------------------------------
variable "domain" {
  description = <<-EOT
    AWS Managed Microsoft AD directory ID (e.g. "d-1234567890").
    Used for SQL Server Windows Authentication via AWS Directory Service.
    Requires domain_iam_role_name or create_domain_iam_role = true.
    Mutually exclusive with domain_fqdn (self-managed AD).
  EOT
  type        = string
  default     = null
}

variable "domain_iam_role_name" {
  description = <<-EOT
    Name of an existing IAM role that allows RDS to make Directory Service API
    calls. Required when domain or domain_fqdn is set and
    create_domain_iam_role = false.
  EOT
  type        = string
  default     = null
}

variable "create_domain_iam_role" {
  description = <<-EOT
    Auto-create an IAM role with AmazonRDSDirectoryServiceAccess and attach it
    to the instance. Set to false to supply your own domain_iam_role_name.
  EOT
  type        = bool
  default     = false
}

# Self-managed (on-premises or non-AWS-Managed) Active Directory
variable "domain_fqdn" {
  description = <<-EOT
    Fully qualified domain name of a self-managed Active Directory
    (e.g. "corp.example.com"). Use this instead of domain when joining
    an on-premises or non-AWS-Managed AD.
  EOT
  type        = string
  default     = null
}

variable "domain_dns_ips" {
  description = <<-EOT
    List of IPv4 addresses for the primary (and optionally secondary) DNS
    servers of the self-managed AD. Required when domain_fqdn is set.
    Example: ["10.0.1.5", "10.0.2.5"]
  EOT
  type        = list(string)
  default     = null
}

variable "domain_ou" {
  description = <<-EOT
    Distinguished Name of the Organizational Unit in which to place the
    computer account when joining a self-managed AD.
    Example: "OU=RDS,OU=Databases,DC=corp,DC=example,DC=com"
  EOT
  type        = string
  default     = null
}

variable "domain_auth_secret_arn" {
  description = <<-EOT
    ARN of a Secrets Manager secret that contains the credentials of a
    service account with permission to join computers to the self-managed AD.
    The secret must have keys "username" and "password".
    Required when domain_fqdn is set.
  EOT
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# IAM Role Associations
# Associates IAM roles to the RDS instance for engine-specific AWS service
# access: Oracle S3 integration, Aurora S3 export, enhanced monitoring
# (beyond the separate monitoring_role_arn), etc.
#
# Each entry:
#   feature_name — the RDS feature the role enables, e.g.:
#     "s3Export"           — Aurora/MySQL export to S3
#     "s3Import"           — Aurora/MySQL import from S3
#     "Lambda"             — invoke Lambda from Oracle/PostgreSQL
#     "SageMaker"          — call SageMaker from Aurora ML
#   role_arn     — ARN of the IAM role to associate
# ---------------------------------------------------------------------------
variable "iam_role_associations" {
  description = <<-EOT
    Map of IAM role associations to attach to the DB instance.
    Key = any logical name; value = { feature_name, role_arn }.
    Common feature names:
      s3Import    — MySQL/Aurora: SELECT INTO OUTFILE S3 / LOAD DATA FROM S3
      s3Export    — Aurora: export query results to S3 (SELECT INTO OUTFILE S3)
      Lambda      — PostgreSQL/Oracle: invoke Lambda functions from SQL
      SageMaker   — Aurora ML: invoke SageMaker endpoints from SQL
  EOT
  type = map(object({
    feature_name = string
    role_arn     = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Snapshot Export to S3
# Exports a DB snapshot to S3 in Apache Parquet format (queryable via Athena)
# ---------------------------------------------------------------------------
variable "snapshot_export" {
  description = <<-EOT
    Export an existing DB snapshot to S3 in Parquet format.
    The exported data is queryable via Amazon Athena.
    Fields:
      export_task_identifier  — unique name for the export task
      source_arn              — ARN of the DB snapshot or cluster snapshot to export
      s3_bucket_name          — destination S3 bucket
      s3_prefix               — (optional) S3 key prefix
      iam_role_arn            — IAM role with s3:PutObject + kms:GenerateDataKey
      kms_key_id              — KMS key ARN for encrypting the S3 export
      export_only             — (optional) list of tables to export, e.g.
                                ["database.table1", "database.table2"].
                                Empty = export entire snapshot.
  EOT
  type = object({
    export_task_identifier = string
    source_arn             = string
    s3_bucket_name         = string
    s3_prefix              = optional(string, "")
    iam_role_arn           = string
    kms_key_id             = string
    export_only            = optional(list(string), [])
  })
  default = null
}
