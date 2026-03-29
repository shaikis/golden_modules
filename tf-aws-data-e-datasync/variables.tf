# ---------------------------------------------------------------------------
# Feature Gates
# ---------------------------------------------------------------------------

variable "create_s3_locations" {
  description = "Set true to create S3 DataSync locations."
  type        = bool
  default     = true
}

variable "create_efs_locations" {
  description = "Set true to create EFS DataSync locations."
  type        = bool
  default     = false
}

variable "create_fsx_windows_locations" {
  description = "Set true to create FSx for Windows DataSync locations."
  type        = bool
  default     = false
}

variable "create_fsx_lustre_locations" {
  description = "Set true to create FSx for Lustre DataSync locations."
  type        = bool
  default     = false
}

variable "create_nfs_locations" {
  description = "Set true to create NFS (on-premises) DataSync locations."
  type        = bool
  default     = false
}

variable "create_smb_locations" {
  description = "Set true to create SMB DataSync locations."
  type        = bool
  default     = false
}

variable "create_hdfs_locations" {
  description = "Set true to create HDFS DataSync locations."
  type        = bool
  default     = false
}

variable "create_object_storage_locations" {
  description = "Set true to create generic object storage DataSync locations."
  type        = bool
  default     = false
}

variable "create_agents" {
  description = "Set true to activate DataSync agents (required for on-premises locations)."
  type        = bool
  default     = false
}

variable "auto_activate_agents" {
  description = <<-EOT
    When true, the module automatically provisions EC2 instances from the
    DataSync agent AMI, registers them via a Lambda function, and stores the
    agent ARNs in SSM Parameter Store.  Requires create_agents = true.
    When false (default), you must supply activation_key manually in agents.
  EOT
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Set true to create CloudWatch alarms for DataSync tasks."
  type        = bool
  default     = false
}

variable "create_iam_role" {
  description = "Set true to auto-create the DataSync S3 access IAM role. Set false to pass your own role_arn."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# BYO Foundational
# ---------------------------------------------------------------------------

variable "role_arn" {
  description = "Existing IAM role ARN for DataSync S3 access (used when create_iam_role = false)."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN from tf-aws-kms for S3 encryption."
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Global Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Optional prefix prepended to auto-generated resource names."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------

variable "datasync_role_name" {
  description = "Override the auto-generated name for the DataSync IAM role."
  type        = string
  default     = null
}

variable "s3_bucket_arns_for_role" {
  description = "S3 bucket ARNs to grant the DataSync IAM role read/write access."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Alarm Thresholds
# ---------------------------------------------------------------------------

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms."
  type        = number
  default     = 2
}

variable "alarm_period_seconds" {
  description = "Period in seconds for CloudWatch alarm evaluation."
  type        = number
  default     = 300
}

# ---------------------------------------------------------------------------
# Locations — S3
# ---------------------------------------------------------------------------

variable "s3_locations" {
  description = "Map of S3 DataSync locations to create (requires create_s3_locations = true)."
  type = map(object({
    s3_bucket_arn          = string
    subdirectory           = optional(string, "/")
    s3_storage_class       = optional(string, "STANDARD")
    bucket_access_role_arn = optional(string, null)
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — EFS
# ---------------------------------------------------------------------------

variable "efs_locations" {
  description = "Map of EFS DataSync locations to create (requires create_efs_locations = true)."
  type = map(object({
    efs_file_system_arn    = string
    subdirectory           = optional(string, "/")
    in_transit_encryption  = optional(string, "TLS1_2")
    ec2_subnet_arn         = string
    ec2_security_group_arns = list(string)
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — FSx for Windows
# ---------------------------------------------------------------------------

variable "fsx_windows_locations" {
  description = "Map of FSx for Windows DataSync locations (requires create_fsx_windows_locations = true)."
  type = map(object({
    fsx_filesystem_arn  = string
    security_group_arns = list(string)
    user                = string
    password            = string
    domain              = optional(string, null)
    subdirectory        = optional(string, "/")
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — FSx for Lustre
# ---------------------------------------------------------------------------

variable "fsx_lustre_locations" {
  description = "Map of FSx for Lustre DataSync locations (requires create_fsx_lustre_locations = true)."
  type = map(object({
    fsx_filesystem_arn  = string
    security_group_arns = list(string)
    subdirectory        = optional(string, "/")
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — NFS
# ---------------------------------------------------------------------------

variable "nfs_locations" {
  description = "Map of NFS DataSync locations (requires create_nfs_locations = true)."
  type = map(object({
    server_hostname = string
    subdirectory    = string
    agent_arns      = list(string)
    mount_version   = optional(string, "AUTOMATIC")
    tags            = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — SMB
# ---------------------------------------------------------------------------

variable "smb_locations" {
  description = "Map of SMB DataSync locations (requires create_smb_locations = true)."
  type = map(object({
    server_hostname = string
    subdirectory    = string
    user            = string
    password        = string
    domain          = optional(string, null)
    agent_arns      = list(string)
    mount_version   = optional(string, "AUTOMATIC")
    tags            = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — HDFS
# ---------------------------------------------------------------------------

variable "hdfs_locations" {
  description = "Map of HDFS DataSync locations (requires create_hdfs_locations = true)."
  type = map(object({
    subdirectory       = optional(string, "/")
    agent_arns         = list(string)
    replication_factor = optional(number, 3)
    auth_type          = optional(string, "SIMPLE")
    simple_user        = optional(string, null)
    name_nodes = list(object({
      hostname = string
      port     = number
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Locations — Object Storage
# ---------------------------------------------------------------------------

variable "object_storage_locations" {
  description = "Map of generic object storage DataSync locations (requires create_object_storage_locations = true)."
  type = map(object({
    server_hostname  = string
    bucket_name      = string
    server_protocol  = optional(string, "HTTPS")
    server_port      = optional(number, 443)
    subdirectory     = optional(string, "/")
    agent_arns       = list(string)
    access_key       = optional(string, null)
    secret_key       = optional(string, null)
    tags             = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Agents
# ---------------------------------------------------------------------------

variable "agents" {
  description = <<-EOT
    Map of DataSync agent configurations (requires create_agents = true).

    BYO mode (auto_activate_agents = false):
      Provide activation_key obtained manually from the agent console.

    Auto-activation mode (auto_activate_agents = true):
      Provide EC2 launch parameters. The module will:
        1. Launch an EC2 instance with the DataSync agent AMI
        2. Invoke a Lambda that fetches the activation key from the agent
           HTTP endpoint and calls datasync:CreateAgent
        3. Store the agent ARN in SSM Parameter Store at:
           /datasync/<name_prefix>/<key>/arn

    Common fields (both modes):
      name                — friendly agent name in DataSync console
      vpc_endpoint_id     — VPC endpoint ID if using DataSync PrivateLink
      subnet_arns         — subnet ARNs for PrivateLink configuration
      security_group_arns — SG ARNs for PrivateLink configuration
      tags                — extra tags

    Auto-activation-only fields:
      ami_id              — DataSync agent AMI (region-specific; find in
                            AWS console: DataSync > Get started > Amazon EC2)
      instance_type       — EC2 instance type (default: m5.2xlarge)
      subnet_id           — EC2 subnet ID (agent must reach DataSync endpoints)
      ec2_security_group_ids  — SG IDs for the agent EC2 instance
      iam_instance_profile    — instance profile with AmazonSSMManagedInstanceCore
      key_name            — (optional) EC2 SSH key pair name
      private_link_endpoint   — (optional) VPC endpoint IP for PrivateLink activation
      activation_region   — (optional) region to register in (default: current)
  EOT
  type = map(object({
    # BYO mode
    activation_key      = optional(string, null)
    ip_address          = optional(string, null)
    # Auto-activation mode
    ami_id              = optional(string, null)
    instance_type       = optional(string, "m5.2xlarge")
    subnet_id           = optional(string, null)
    ec2_security_group_ids  = optional(list(string), [])
    iam_instance_profile    = optional(string, null)
    key_name            = optional(string, null)
    private_link_endpoint = optional(string, null)
    activation_region   = optional(string, null)
    # Common
    name                = optional(string, null)
    vpc_endpoint_id     = optional(string, null)
    subnet_arns         = optional(list(string), [])
    security_group_arns = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Activation Lambda VPC config (required when auto_activate_agents = true)
# ---------------------------------------------------------------------------
variable "activation_lambda_subnet_ids" {
  description = "Subnet IDs for the activation Lambda (must reach agent EC2 on port 80)."
  type        = list(string)
  default     = []
}
variable "activation_lambda_security_group_ids" {
  description = "Security group IDs for the activation Lambda."
  type        = list(string)
  default     = []
}
variable "activation_lambda_timeout" {
  description = "Timeout seconds for the activation Lambda. Agent boot may take 1-2 minutes."
  type        = number
  default     = 300
}

# ---------------------------------------------------------------------------
# Tasks
# ---------------------------------------------------------------------------

variable "tasks" {
  description = "Map of DataSync Tasks to create."
  type = map(object({
    source_location_key      = string
    destination_location_key = string
    name                     = optional(string, null)
    schedule_expression      = optional(string, null)
    cloudwatch_log_group_arn = optional(string, null)
    bytes_per_second         = optional(number, -1)
    verify_mode              = optional(string, "ONLY_FILES_TRANSFERRED")
    overwrite_mode           = optional(string, "ALWAYS")
    transfer_mode            = optional(string, "CHANGED")
    atime                    = optional(string, "BEST_EFFORT")
    mtime                    = optional(string, "PRESERVE")
    uid                      = optional(string, "INT_VALUE")
    gid                      = optional(string, "INT_VALUE")
    posix_permissions        = optional(string, "PRESERVE")
    preserve_deleted_files   = optional(string, "PRESERVE")
    preserve_devices         = optional(string, "NONE")
    task_queueing            = optional(string, "ENABLED")
    log_level                = optional(string, "TRANSFER")
    include_patterns         = optional(list(string), [])
    exclude_patterns         = optional(list(string), [])
    report_s3_bucket_arn     = optional(string, null)
    report_s3_prefix         = optional(string, null)
    report_output_type       = optional(string, "SUMMARY_ONLY")
    tags                     = optional(map(string), {})
  }))
  default = {}
}
