variable "name"        { type = string }
variable "name_prefix" { type = string; default = "" }
variable "environment" { type = string; default = "dev" }
variable "project"     { type = string; default = "" }
variable "owner"       { type = string; default = "" }
variable "cost_center" { type = string; default = "" }
variable "tags"        { type = map(string); default = {} }

# ---------------------------------------------------------------------------
# Agent — EC2-based DataSync agent with automated activation
# ---------------------------------------------------------------------------
variable "agents" {
  description = <<-EOT
    Map of DataSync agent configurations. Each agent is:
      1. An EC2 instance running the AWS DataSync agent AMI
      2. Automatically activated via a Lambda function that fetches the
         activation key from the agent's local HTTP endpoint
      3. Registered as an aws_datasync_agent resource

    Fields:
      ami_id                — DataSync agent AMI ID (region-specific; find in
                              AWS console: DataSync > Agents > Deploy agent > Amazon EC2)
      instance_type         — EC2 instance type (default: m5.2xlarge)
      subnet_id             — Subnet for the agent EC2 instance
      security_group_ids    — SGs: must allow outbound 443 to DataSync endpoints
                              and inbound 80 from the activation Lambda/VPC
      iam_instance_profile  — IAM instance profile ARN (must have
                              AmazonSSMManagedInstanceCore + datasync:* permissions)
      vpc_id                — VPC ID (used for Lambda activation function VPC config)
      activation_region     — AWS region to register the agent in (default: current)
      private_link_endpoint — (optional) VPC endpoint IP for DataSync PrivateLink
      name                  — friendly name for the registered agent
      key_name              — (optional) EC2 key pair name for SSH access
      additional_tags       — (optional) extra tags on the EC2 instance
  EOT
  type = map(object({
    ami_id               = string
    instance_type        = optional(string, "m5.2xlarge")
    subnet_id            = string
    security_group_ids   = list(string)
    iam_instance_profile = string
    vpc_id               = string
    activation_region    = optional(string, null) # defaults to current region
    private_link_endpoint = optional(string, null)
    name                 = optional(string, null)
    key_name             = optional(string, null)
    additional_tags      = optional(map(string), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Activation Lambda configuration
# One Lambda is created per agent to perform the HTTP activation call.
# ---------------------------------------------------------------------------
variable "activation_lambda_subnet_ids" {
  description = "Subnet IDs for the activation Lambda functions (must be in same VPC as agents)."
  type        = list(string)
  default     = []
}
variable "activation_lambda_security_group_ids" {
  description = "Security group IDs for the activation Lambda functions."
  type        = list(string)
  default     = []
}
variable "activation_lambda_timeout" {
  description = "Timeout in seconds for the activation Lambda. The agent may take a few minutes to boot."
  type        = number
  default     = 300
}

# ---------------------------------------------------------------------------
# Locations
# ---------------------------------------------------------------------------
variable "s3_locations" {
  description = <<-EOT
    S3 bucket locations for DataSync tasks.
    Fields:
      s3_bucket_arn       — ARN of the S3 bucket
      subdirectory        — S3 prefix (e.g. "/data/incoming/")
      s3_storage_class    — STANDARD | INTELLIGENT_TIERING | STANDARD_IA |
                            ONEZONE_IA | GLACIER | DEEP_ARCHIVE | GLACIER_IR
      s3_config_bucket_access_role_arn — IAM role ARN with s3:GetObject, s3:PutObject,
                                         s3:DeleteObject, s3:ListBucket on the bucket
      server_side_encryption_type — AES256 | aws:kms (for destination locations)
      kms_key_arn         — KMS key ARN (required when sse = aws:kms)
      agent_arns          — (optional) list of agent ARNs for S3 on Outposts
  EOT
  type = map(object({
    s3_bucket_arn    = string
    subdirectory     = optional(string, "/")
    s3_storage_class = optional(string, "STANDARD")
    s3_config_bucket_access_role_arn = string
    agent_arns       = optional(list(string), [])
  }))
  default = {}
}

variable "efs_locations" {
  description = <<-EOT
    Amazon EFS locations for DataSync tasks.
    Fields:
      efs_file_system_arn   — ARN of the EFS file system
      subdirectory          — EFS path (default: "/")
      ec2_config            — { subnet_arn, security_group_arns } for DataSync EC2 access
      in_transit_encryption — NONE | TLS1_2
      access_point_arn      — (optional) EFS access point ARN
      file_system_access_role_arn — (optional) IAM role for EFS access point permissions
  EOT
  type = map(object({
    efs_file_system_arn = string
    subdirectory        = optional(string, "/")
    ec2_config = object({
      subnet_arn          = string
      security_group_arns = list(string)
    })
    in_transit_encryption           = optional(string, "TLS1_2")
    access_point_arn                = optional(string, null)
    file_system_access_role_arn     = optional(string, null)
  }))
  default = {}
}

variable "nfs_locations" {
  description = <<-EOT
    NFS server locations (on-premises or EC2-hosted NFS).
    Fields:
      server_hostname — DNS name or IP of the NFS server
      subdirectory    — NFS export path (e.g. "/exports/data")
      agent_arns      — list of agent ARNs that can access this NFS server
      mount_options   — { version: AUTOMATIC | NFS3 | NFS4_0 | NFS4_1 }
  EOT
  type = map(object({
    server_hostname = string
    subdirectory    = string
    agent_arns      = list(string)
    mount_options = optional(object({
      version = optional(string, "AUTOMATIC")
    }), {})
  }))
  default = {}
}

variable "smb_locations" {
  description = <<-EOT
    SMB/CIFS share locations (Windows file shares, on-premises).
    Fields:
      server_hostname — DNS name or IP of the SMB server
      subdirectory    — UNC share path (e.g. "\\share\\data")
      domain          — (optional) Active Directory domain
      user            — username with share access
      password_secret_arn — Secrets Manager ARN containing the password
      agent_arns      — list of agent ARNs
      mount_options   — { version: AUTOMATIC | SMB2 | SMB3 | SMB2_0 }
  EOT
  type = map(object({
    server_hostname     = string
    subdirectory        = string
    domain              = optional(string, null)
    user                = string
    password_secret_arn = string
    agent_arns          = list(string)
    mount_options = optional(object({
      version = optional(string, "AUTOMATIC")
    }), {})
  }))
  default = {}
}

variable "fsx_windows_locations" {
  description = <<-EOT
    Amazon FSx for Windows File Server locations.
    Fields:
      fsx_filesystem_arn  — ARN of the FSx for Windows file system
      subdirectory        — (optional) subdirectory path
      domain              — Active Directory domain name
      user                — AD user with access
      password_secret_arn — Secrets Manager ARN containing the password
      security_group_arns — SG ARNs for DataSync access to FSx
  EOT
  type = map(object({
    fsx_filesystem_arn  = string
    subdirectory        = optional(string, "\\")
    domain              = string
    user                = string
    password_secret_arn = string
    security_group_arns = list(string)
  }))
  default = {}
}

variable "fsx_lustre_locations" {
  description = <<-EOT
    Amazon FSx for Lustre locations.
    Fields:
      fsx_filesystem_arn  — ARN of the FSx for Lustre file system
      subdirectory        — (optional) subdirectory
      security_group_arns — SG ARNs for DataSync access
  EOT
  type = map(object({
    fsx_filesystem_arn  = string
    subdirectory        = optional(string, "/")
    security_group_arns = list(string)
  }))
  default = {}
}

variable "fsx_openzfs_locations" {
  description = <<-EOT
    Amazon FSx for OpenZFS locations.
    Fields:
      fsx_filesystem_arn  — ARN of the FSx for OpenZFS file system
      subdirectory        — mount path
      security_group_arns — SG ARNs
      protocol            — { nfs: { mount_options: { version } } }
  EOT
  type = map(object({
    fsx_filesystem_arn  = string
    subdirectory        = optional(string, "/")
    security_group_arns = list(string)
    protocol = optional(object({
      nfs = optional(object({
        mount_options = optional(object({
          version = optional(string, "AUTOMATIC")
        }), {})
      }), {})
    }), {})
  }))
  default = {}
}

variable "object_storage_locations" {
  description = <<-EOT
    Self-managed object storage locations (non-S3 object stores, e.g. MinIO, Wasabi).
    Fields:
      server_hostname     — hostname of the object storage server
      bucket_name         — bucket/container name
      subdirectory        — (optional) key prefix
      server_port         — port (default: 443)
      server_protocol     — HTTPS | HTTP
      access_key          — access key ID
      secret_key_secret_arn — Secrets Manager ARN containing the secret key
      agent_arns          — list of agent ARNs
  EOT
  type = map(object({
    server_hostname       = string
    bucket_name           = string
    subdirectory          = optional(string, "/")
    server_port           = optional(number, 443)
    server_protocol       = optional(string, "HTTPS")
    access_key            = string
    secret_key_secret_arn = string
    agent_arns            = list(string)
  }))
  default = {}
}

variable "hdfs_locations" {
  description = <<-EOT
    Hadoop HDFS locations.
    Fields:
      name_nodes          — list of { hostname, port } for HDFS NameNodes
      subdirectory        — HDFS path
      agent_arns          — list of agent ARNs
      authentication_type — SIMPLE | KERBEROS
      simple_user         — username for SIMPLE auth
      kerberos_principal  — Kerberos principal (for KERBEROS auth)
      kerberos_keytab     — base64-encoded keytab file
      kerberos_krb5_conf  — base64-encoded krb5.conf
      block_size          — HDFS block size in bytes (default: 134217728 = 128 MiB)
      replication_factor  — HDFS replication factor (default: 3)
  EOT
  type = map(object({
    name_nodes = list(object({
      hostname = string
      port     = number
    }))
    subdirectory        = string
    agent_arns          = list(string)
    authentication_type = optional(string, "SIMPLE")
    simple_user         = optional(string, null)
    kerberos_principal  = optional(string, null)
    kerberos_keytab     = optional(string, null)
    kerberos_krb5_conf  = optional(string, null)
    block_size          = optional(number, 134217728)
    replication_factor  = optional(number, 3)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Tasks
# ---------------------------------------------------------------------------
variable "tasks" {
  description = <<-EOT
    DataSync task definitions. A task moves data from a source location to
    a destination location.

    Fields:
      source_location_key      — key from one of the *_locations maps
      source_location_type     — s3 | efs | nfs | smb | fsx_windows | fsx_lustre |
                                  fsx_openzfs | object_storage | hdfs
      destination_location_key — key from one of the *_locations maps
      destination_location_type — same type values as above
      cloudwatch_log_group_arn — (optional) CloudWatch log group for task logs
      task_report_config       — (optional) S3 destination for task execution reports
      options                  — transfer options (see below)
      schedule                 — { schedule_expression } for cron-based execution
      excludes                 — list of { filter_type, value } exclusion filters
      includes                 — list of { filter_type, value } inclusion filters
      name                     — friendly name

    options fields:
      atime                — NONE | BEST_EFFORT
      bytes_per_second     — bandwidth throttle in bytes/sec (-1 = unlimited)
      gid                  — NONE | INT_VALUE | NAME | BOTH
      log_level            — OFF | BASIC | TRANSFER
      mtime                — NONE | PRESERVE
      object_tags          — PRESERVE | NONE (S3 locations)
      overwrite_mode       — ALWAYS | NEVER
      posix_permissions    — NONE | PRESERVE
      preserve_deleted_files — PRESERVE | REMOVE
      preserve_devices     — NONE | PRESERVE
      security_descriptor_copy_flags — NONE | OWNER_DACL | OWNER_DACL_SACL (SMB/FSx)
      task_queueing        — ENABLED | DISABLED
      transfer_mode        — CHANGED | ALL
      uid                  — NONE | INT_VALUE | NAME | BOTH
      verify_mode          — POINT_IN_TIME_CONSISTENT | ONLY_FILES_TRANSFERRED | NONE
  EOT
  type = map(object({
    source_location_key       = string
    source_location_type      = string
    destination_location_key  = string
    destination_location_type = string
    name                      = optional(string, null)
    cloudwatch_log_group_arn  = optional(string, null)

    task_report_config = optional(object({
      s3_bucket_arn     = string
      s3_subdirectory   = optional(string, "reports/")
      s3_bucket_access_role_arn = string
      output_type       = optional(string, "STANDARD")    # STANDARD | CUSTOM
      report_level      = optional(string, "ERRORS_ONLY") # ERRORS_ONLY | SUCCESSES_AND_ERRORS
    }), null)

    options = optional(object({
      atime                          = optional(string, "BEST_EFFORT")
      bytes_per_second               = optional(number, -1)
      gid                            = optional(string, "INT_VALUE")
      log_level                      = optional(string, "TRANSFER")
      mtime                          = optional(string, "PRESERVE")
      object_tags                    = optional(string, "PRESERVE")
      overwrite_mode                 = optional(string, "ALWAYS")
      posix_permissions              = optional(string, "PRESERVE")
      preserve_deleted_files         = optional(string, "PRESERVE")
      preserve_devices               = optional(string, "NONE")
      security_descriptor_copy_flags = optional(string, "NONE")
      task_queueing                  = optional(string, "ENABLED")
      transfer_mode                  = optional(string, "CHANGED")
      uid                            = optional(string, "INT_VALUE")
      verify_mode                    = optional(string, "POINT_IN_TIME_CONSISTENT")
    }), {})

    schedule = optional(object({
      schedule_expression = string # cron or rate expression
    }), null)

    excludes = optional(list(object({
      filter_type = string # SIMPLE_PATTERN
      value       = string # e.g. "/tmp|*.log"
    })), [])

    includes = optional(list(object({
      filter_type = string
      value       = string
    })), [])
  }))
  default = {}
}
