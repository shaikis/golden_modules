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
  type = map(string)
  default = {
  }
}

variable "kms_key_arn" {
  description = "KMS key for all FSx volume encryption."
  type        = string
  default     = null
}

# ===========================================================================
# FSx for Windows File Server
# ===========================================================================
variable "windows" {
  description = "FSx for Windows File Server configuration. null = disabled."
  type = object({
    storage_capacity                  = number
    subnet_ids                        = list(string) # 1 (single-AZ) or 2 (multi-AZ)
    security_group_ids                = optional(list(string), [])
    deployment_type                   = optional(string, "MULTI_AZ_1") # MULTI_AZ_1 | SINGLE_AZ_1 | SINGLE_AZ_2
    preferred_subnet_id               = optional(string, null)         # required for MULTI_AZ_1
    storage_type                      = optional(string, "SSD")        # SSD | HDD
    throughput_capacity               = optional(number, 512)
    automatic_backup_retention_days   = optional(number, 7)
    daily_automatic_backup_start_time = optional(string, "02:00")
    weekly_maintenance_start_time     = optional(string, "1:02:00")
    copy_tags_to_backups              = optional(bool, true)
    skip_final_backup                 = optional(bool, false)
    aliases                           = optional(list(string), []) # DNS aliases

    # Active Directory
    active_directory_id = optional(string, null) # AWS Managed AD (takes priority)
    self_managed_ad = optional(object({
      domain_name             = string
      username                = string
      password                = string
      dns_ips                 = list(string)
      organizational_unit     = optional(string, null)
      file_system_admin_group = optional(string, "Domain Admins")
    }), null)

    # Audit logs
    audit_log_destination       = optional(string, null)       # CloudWatch log group ARN
    file_access_audit_log_level = optional(string, "DISABLED") # DISABLED | SUCCESS_ONLY | FAILURE_ONLY | SUCCESS_AND_FAILURE
  })
  default = null
}

# ===========================================================================
# FSx for Lustre
# ===========================================================================
variable "lustre" {
  description = "FSx for Lustre configuration. null = disabled."
  type = object({
    storage_capacity                = number
    subnet_ids                      = list(string)
    security_group_ids              = optional(list(string), [])
    deployment_type                 = optional(string, "SCRATCH_2") # SCRATCH_1 | SCRATCH_2 | PERSISTENT_1 | PERSISTENT_2
    storage_type                    = optional(string, "SSD")
    per_unit_storage_throughput     = optional(number, null)   # required for PERSISTENT_1/2
    data_compression_type           = optional(string, "NONE") # NONE | LZ4
    automatic_backup_retention_days = optional(number, 0)
    copy_tags_to_backups            = optional(bool, false)
    weekly_maintenance_start_time   = optional(string, null)
    file_system_type_version        = optional(string, "2.12")

    # S3 data repository link
    import_path = optional(string, null)
    export_path = optional(string, null)
  })
  default = null
}

# ===========================================================================
# FSx for NetApp ONTAP
# ===========================================================================
variable "ontap" {
  description = "FSx for NetApp ONTAP file system configuration. null = disabled."
  type = object({
    storage_capacity                  = number
    subnet_ids                        = list(string) # 2 subnets for MULTI_AZ_1
    security_group_ids                = optional(list(string), [])
    deployment_type                   = optional(string, "MULTI_AZ_1") # MULTI_AZ_1 | SINGLE_AZ_1 | SINGLE_AZ_2
    preferred_subnet_id               = optional(string, null)
    throughput_capacity               = optional(number, 512)
    weekly_maintenance_start_time     = optional(string, "1:02:00")
    automatic_backup_retention_days   = optional(number, 7)
    daily_automatic_backup_start_time = optional(string, "02:00")
    fsx_admin_password                = optional(string, null)
    route_table_ids                   = optional(list(string), [])
    ha_pairs                          = optional(number, 1)

    # Storage Virtual Machines
    svms = optional(map(object({
      name                       = string
      root_volume_security_style = optional(string, "UNIX") # UNIX | NTFS | MIXED
      svm_admin_password         = optional(string, null)

      # Active Directory (for NTFS/MIXED volumes)
      active_directory = optional(object({
        dns_ips                                = list(string)
        domain_name                            = string
        password                               = string
        username                               = string
        file_system_admin_group                = optional(string, "Domain Admins")
        organizational_unit_distinguished_name = optional(string, null)
        netbios_name                           = optional(string, null)
      }), null)

      # Volumes on this SVM
      volumes = optional(map(object({
        name               = string
        junction_path      = string # e.g. /vol1
        size_in_megabytes  = number
        security_style     = optional(string, "UNIX")
        storage_efficiency = optional(bool, true)
        tiering_policy = optional(object({
          name           = string # SNAPSHOT_ONLY | AUTO | ALL | NONE
          cooling_period = optional(number, null)
        }), null)
        snapshot_policy                      = optional(string, "default")
        copy_tags_to_backups                 = optional(bool, true)
        bypass_snaplock_enterprise_retention = optional(bool, false)
      })), {})
    })), {})
  })
  default = null
}

# ===========================================================================
# AWS Backup for FSx ONTAP — Cross-Region (choice-based)
# Enable each toggle independently based on your DR requirements
# ===========================================================================

variable "enable_ontap_backup" {
  description = "Enable AWS Backup plan for FSx ONTAP file system"
  type        = bool
  default     = false
}

variable "ontap_backup_vault_name" {
  description = "Name for the AWS Backup vault in the primary region. Defaults to <name>-fsx-vault."
  type        = string
  default     = null
}

variable "ontap_backup_schedule" {
  description = "Cron schedule for ONTAP backups (UTC). Default = daily at 02:00 UTC."
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "ontap_backup_retention_days" {
  description = "Number of days to retain local ONTAP backups before deletion"
  type        = number
  default     = 7
}

variable "enable_ontap_cross_region_backup" {
  description = "Copy ONTAP backups to a destination region for DR. Requires enable_ontap_backup = true."
  type        = bool
  default     = false
}

variable "ontap_cross_region_backup_vault_arn" {
  description = <<-EOT
    ARN of the AWS Backup vault in the destination/DR region.
    You must pre-create this vault in the destination region before applying this module.
    Example: "arn:aws:backup:us-west-2:123456789012:backup-vault:my-dr-vault"
  EOT
  type        = string
  default     = null
}

variable "ontap_cross_region_backup_kms_key_arn" {
  description = "KMS key ARN in the destination region for encrypting cross-region backup copies. Null = AWS-managed key."
  type        = string
  default     = null
}

variable "ontap_cross_region_backup_retention_days" {
  description = "Number of days to retain ONTAP backups in the destination region"
  type        = number
  default     = 30
}

# ===========================================================================
# FSx for OpenZFS
# ===========================================================================
variable "openzfs" {
  description = "FSx for OpenZFS configuration. null = disabled."
  type = object({
    storage_capacity                  = number
    subnet_ids                        = list(string)
    security_group_ids                = optional(list(string), [])
    deployment_type                   = optional(string, "SINGLE_AZ_1") # SINGLE_AZ_1 | SINGLE_AZ_2 | MULTI_AZ_1
    throughput_capacity               = optional(number, 64)
    storage_type                      = optional(string, "SSD")
    automatic_backup_retention_days   = optional(number, 7)
    daily_automatic_backup_start_time = optional(string, "02:00")
    copy_tags_to_backups              = optional(bool, true)
    skip_final_backup                 = optional(bool, false)
    weekly_maintenance_start_time     = optional(string, "1:02:00")

    # Root volume options
    root_volume_copy_tags_to_snapshots = optional(bool, true)
    root_volume_data_compression_type  = optional(string, "NONE") # NONE | ZSTD | LZ4
    root_volume_read_only              = optional(bool, false)
    root_volume_record_size_kib        = optional(number, 128)

    # Child volumes
    volumes = optional(map(object({
      parent_volume_id                 = optional(string, null) # null = attach to root
      name                             = string
      junction_path                    = optional(string, null) # e.g. /data
      storage_capacity_quota_gib       = optional(number, null)
      storage_capacity_reservation_gib = optional(number, null)
      data_compression_type            = optional(string, "NONE")
      read_only                        = optional(bool, false)
      record_size_kib                  = optional(number, 128)
      copy_tags_to_snapshots           = optional(bool, true)
      nfs_exports = optional(list(object({
        client_configurations = list(object({
          clients = string
          options = list(string)
        }))
      })), [])
    })), {})
  })
  default = null
}
