# ---------------------------------------------------------------------------
# DataSync Tasks
# ---------------------------------------------------------------------------

locals {
  # Build a unified map of all location ARNs so tasks can reference any
  # location type by a single key without knowing its type.
  all_location_arns = merge(
    { for k, v in aws_datasync_location_s3.this : k => v.arn },
    { for k, v in aws_datasync_location_efs.this : k => v.arn },
    { for k, v in aws_datasync_location_fsx_windows_file_system.this : k => v.arn },
    { for k, v in aws_datasync_location_fsx_lustre_file_system.this : k => v.arn },
    { for k, v in aws_datasync_location_nfs.this : k => v.arn },
    { for k, v in aws_datasync_location_smb.this : k => v.arn },
    { for k, v in aws_datasync_location_hdfs.this : k => v.arn },
    { for k, v in aws_datasync_location_object_storage.this : k => v.arn },
  )
}

resource "aws_datasync_task" "this" {
  for_each = var.tasks

  name                     = each.value.name != null ? each.value.name : each.key
  source_location_arn      = local.all_location_arns[each.value.source_location_key]
  destination_location_arn = local.all_location_arns[each.value.destination_location_key]
  cloudwatch_log_group_arn = each.value.cloudwatch_log_group_arn

  options {
    atime                          = each.value.atime
    bytes_per_second               = each.value.bytes_per_second
    gid                            = each.value.gid
    mtime                          = each.value.mtime
    overwrite_mode                 = each.value.overwrite_mode
    posix_permissions              = each.value.posix_permissions
    preserve_deleted_files         = each.value.preserve_deleted_files
    preserve_devices               = each.value.preserve_devices
    task_queueing                  = each.value.task_queueing
    transfer_mode                  = each.value.transfer_mode
    uid                            = each.value.uid
    verify_mode                    = each.value.verify_mode
    log_level                      = each.value.log_level
  }

  dynamic "includes" {
    for_each = each.value.include_patterns
    content {
      filter_type = "SIMPLE_PATTERN"
      value       = includes.value
    }
  }

  dynamic "excludes" {
    for_each = each.value.exclude_patterns
    content {
      filter_type = "SIMPLE_PATTERN"
      value       = excludes.value
    }
  }

  dynamic "schedule" {
    for_each = each.value.schedule_expression != null ? [1] : []
    content {
      schedule_expression = each.value.schedule_expression
    }
  }

  dynamic "task_report_config" {
    for_each = each.value.report_s3_bucket_arn != null ? [1] : []
    content {
      s3_destination {
        bucket_access_role_arn = local.effective_role_arn
        s3_bucket_arn          = each.value.report_s3_bucket_arn
        subdirectory           = each.value.report_s3_prefix != null ? each.value.report_s3_prefix : "datasync-reports/${each.key}"
      }
      output_type              = each.value.report_output_type
      report_level             = "SUCCESSES_AND_ERRORS"
      overrides_verified_level = "ERRORS_ONLY"
      overrides_deleted_level  = "ERRORS_ONLY"
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.value.name != null ? each.value.name : each.key
  })
}
