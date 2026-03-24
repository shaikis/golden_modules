# ---------------------------------------------------------------------------
# Complete Example — On-prem NFS → S3 raw, S3 raw → S3 archive,
#                    EFS → S3 backup, scheduled nightly, task reports, alarms
# ---------------------------------------------------------------------------

module "datasync" {
  source = "../.."

  create_iam_role     = true
  create_s3_locations = true
  create_efs_locations = true
  create_nfs_locations = true
  create_alarms       = true

  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  s3_bucket_arns_for_role = [
    var.raw_bucket_arn,
    var.archive_bucket_arn,
  ]

  # ── S3 Locations ──────────────────────────────────────────────────────────
  s3_locations = {
    "s3-raw-zone" = {
      s3_bucket_arn    = var.raw_bucket_arn
      subdirectory     = "/incoming/"
      s3_storage_class = "STANDARD"
    }
    "s3-archive-zone" = {
      s3_bucket_arn    = var.archive_bucket_arn
      subdirectory     = "/archive/"
      s3_storage_class = "GLACIER"
    }
    "s3-efs-backup" = {
      s3_bucket_arn    = var.raw_bucket_arn
      subdirectory     = "/efs-backup/"
      s3_storage_class = "STANDARD_IA"
    }
  }

  # ── EFS Location ──────────────────────────────────────────────────────────
  efs_locations = {
    "efs-primary" = {
      efs_file_system_arn     = var.efs_file_system_arn
      subdirectory            = "/"
      in_transit_encryption   = "TLS1_2"
      ec2_subnet_arn          = var.efs_subnet_arn
      ec2_security_group_arns = var.efs_security_group_arns
    }
  }

  # ── NFS Location (on-premises) ────────────────────────────────────────────
  nfs_locations = {
    "onprem-nfs-share" = {
      server_hostname = "192.168.10.50"
      subdirectory    = "/exports/data"
      agent_arns      = var.nfs_agent_arns
      mount_version   = "NFS4_1"
    }
  }

  # ── Tasks ─────────────────────────────────────────────────────────────────
  tasks = {
    "onprem-nfs-to-s3-raw" = {
      source_location_key      = "onprem-nfs-share"
      destination_location_key = "s3-raw-zone"
      name                     = "On-Prem NFS to S3 Raw Zone"
      schedule_expression      = "cron(0 2 * * ? *)"
      cloudwatch_log_group_arn = var.cloudwatch_log_group_arn
      bytes_per_second         = 104857600 # 100 MB/s cap during business hours
      transfer_mode            = "CHANGED"
      verify_mode              = "ONLY_FILES_TRANSFERRED"
      overwrite_mode           = "ALWAYS"
      report_s3_bucket_arn     = var.report_bucket_arn
      report_s3_prefix         = "reports/nfs-to-raw"
      report_output_type       = "STANDARD"
      exclude_patterns         = ["*.tmp", "*.lock"]
    }

    "s3-raw-to-archive" = {
      source_location_key      = "s3-raw-zone"
      destination_location_key = "s3-archive-zone"
      name                     = "S3 Raw to Archive Cold Storage"
      schedule_expression      = "cron(0 3 * * ? *)"
      cloudwatch_log_group_arn = var.cloudwatch_log_group_arn
      transfer_mode            = "ALL"
      verify_mode              = "ONLY_FILES_TRANSFERRED"
      overwrite_mode           = "NEVER"
      report_s3_bucket_arn     = var.report_bucket_arn
      report_s3_prefix         = "reports/raw-to-archive"
    }

    "efs-to-s3-backup" = {
      source_location_key      = "efs-primary"
      destination_location_key = "s3-efs-backup"
      name                     = "EFS to S3 Backup"
      schedule_expression      = "cron(0 4 * * ? *)"
      cloudwatch_log_group_arn = var.cloudwatch_log_group_arn
      transfer_mode            = "CHANGED"
      verify_mode              = "ONLY_FILES_TRANSFERRED"
      posix_permissions        = "PRESERVE"
      preserve_deleted_files   = "REMOVE"
      report_s3_bucket_arn     = var.report_bucket_arn
      report_s3_prefix         = "reports/efs-backup"
    }
  }

  tags = {
    Environment = "production"
    Project     = "data-migration"
    ManagedBy   = "terraform"
  }
}
