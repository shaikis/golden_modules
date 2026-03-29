# ---------------------------------------------------------------------------
# Identity / Naming
# ---------------------------------------------------------------------------
variable "name" {
  description = "Short logical name for this EFS (e.g. 'shared', 'app-data')"
  type        = string
  default     = "efs"
}

variable "name_prefix" {
  description = "Override the auto-generated prefix (project-environment). Leave empty to use default."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Team or person responsible for this resource"
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center code for billing allocation"
  type        = string
  default     = "shared"
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Feature Toggles (choice-based — enable only what you need)
# ---------------------------------------------------------------------------
variable "create" {
  description = "Master toggle: set false to disable all resources in this module"
  type        = bool
  default     = true
}

variable "create_security_group" {
  description = "Create a dedicated EFS security group. Disable if you supply your own via security_group_ids."
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable EFS lifecycle transition policies (IA tiering + primary storage recall)"
  type        = bool
  default     = true
}

variable "enable_backup_policy" {
  description = "Enable AWS Backup integration for this EFS file system"
  type        = bool
  default     = true
}

variable "enable_replication" {
  description = "Enable cross-region EFS replication to a secondary region"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Core EFS Settings
# ---------------------------------------------------------------------------
variable "encrypted" {
  description = "Encrypt the EFS file system with KMS"
  type        = bool
  default     = true
}

variable "availability_zone_name" {
  description = "Availability Zone name for One Zone EFS, for example us-east-1a. Leave null for Regional EFS."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Null = AWS-managed key (aws/elasticfilesystem)."
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "EFS performance mode: generalPurpose (default, <7000 clients) or maxIO (big data, higher latency)"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "performance_mode must be 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "EFS throughput mode: elastic (recommended), bursting (default AWS), or provisioned"
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "throughput_mode must be 'bursting', 'provisioned', or 'elastic'."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Throughput in MiB/s when throughput_mode = 'provisioned'. Ignored otherwise."
  type        = number
  default     = null
}

# ---------------------------------------------------------------------------
# Lifecycle Policies
# ---------------------------------------------------------------------------
variable "transition_to_ia" {
  description = <<-EOT
    Move files to Infrequent Access (IA) storage after N days without access.
    Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS
    Set to null to disable IA tiering.
  EOT
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "transition_to_primary_storage_class" {
  description = <<-EOT
    Move files back to primary storage on first access from IA.
    Valid values: AFTER_1_ACCESS  |  null = disable recall
  EOT
  type        = string
  default     = "AFTER_1_ACCESS"
}

# ---------------------------------------------------------------------------
# Network / Mount Targets
# ---------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID — required when create_security_group = true"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs to create mount targets in (one per AZ for high availability)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Additional existing security group IDs to attach to mount targets"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access EFS on NFS port 2049 (used when create_security_group = true)"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access EFS on NFS port 2049 (used when create_security_group = true)"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Access Points (choice-based — add as many as needed, or leave empty)
# ---------------------------------------------------------------------------
variable "access_points" {
  description = <<-EOT
    Map of EFS access points to create. Each access point provides an application-specific
    entry point with its own POSIX identity and root directory.

    Example:
    access_points = {
      app = {
        path        = "/app"
        owner_uid   = 1000
        owner_gid   = 1000
        permissions = "755"
        posix_uid   = 1000
        posix_gid   = 1000
      }
    }
  EOT
  type = map(object({
    path           = string
    owner_uid      = number
    owner_gid      = number
    permissions    = string
    posix_uid      = number
    posix_gid      = number
    secondary_gids = optional(list(number), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Cross-Region Replication (choice-based — enable when needed)
# ---------------------------------------------------------------------------
variable "replication_destination_region" {
  description = "AWS region to replicate EFS data to (e.g. 'us-west-2'). Required when enable_replication = true."
  type        = string
  default     = null
}

variable "replication_destination_kms_key_arn" {
  description = "KMS key ARN in the destination region to encrypt the replicated file system. Null = AWS-managed key."
  type        = string
  default     = null
}

variable "replication_destination_availability_zone" {
  description = "Specific AZ in the destination region for the replicated file system (optional)."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# File System Policy
# ---------------------------------------------------------------------------
variable "file_system_policy" {
  description = "Optional JSON IAM policy document to attach to the EFS file system."
  type        = string
  default     = null
}

variable "bypass_policy_lockout_safety_check" {
  description = "Whether to allow a file system policy that could lock out future updates. Use with care."
  type        = bool
  default     = false
}
