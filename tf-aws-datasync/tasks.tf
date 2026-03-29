# =============================================================================
# DataSync Tasks
# Each task connects a source location to a destination location and
# defines how the transfer is performed.
# =============================================================================

locals {
  # Build a flat lookup map: type+key → ARN
  location_arns = merge(
    { for k, v in aws_datasync_location_s3.this             : "s3:${k}"             => v.arn },
    { for k, v in aws_datasync_location_efs.this            : "efs:${k}"            => v.arn },
    { for k, v in aws_datasync_location_nfs.this            : "nfs:${k}"            => v.arn },
    { for k, v in aws_datasync_location_smb.this            : "smb:${k}"            => v.arn },
    { for k, v in aws_datasync_location_fsx_windows_file_system.this : "fsx_windows:${k}" => v.arn },
    { for k, v in aws_datasync_location_fsx_lustre_file_system.this  : "fsx_lustre:${k}"  => v.arn },
    { for k, v in aws_datasync_location_fsx_openzfs_file_system.this : "fsx_openzfs:${k}" => v.arn },
    { for k, v in aws_datasync_location_object_storage.this : "object_storage:${k}" => v.arn },
    { for k, v in aws_datasync_location_hdfs.this           : "hdfs:${k}"           => v.arn },
  )
}

resource "aws_datasync_task" "this" {
  for_each = var.tasks

  name                     = coalesce(each.value.name, each.key)
  source_location_arn      = local.location_arns["${each.value.source_location_type}:${each.value.source_location_key}"]
  destination_location_arn = local.location_arns["${each.value.destination_location_type}:${each.value.destination_location_key}"]
  cloudwatch_log_group_arn = each.value.cloudwatch_log_group_arn

  dynamic "options" {
    for_each = each.value.options != null ? [each.value.options] : [{}]
    content {
      atime                          = options.value.atime
      bytes_per_second               = options.value.bytes_per_second
      gid                            = options.value.gid
      log_level                      = options.value.log_level
      mtime                          = options.value.mtime
      object_tags                    = options.value.object_tags
      overwrite_mode                 = options.value.overwrite_mode
      posix_permissions              = options.value.posix_permissions
      preserve_deleted_files         = options.value.preserve_deleted_files
      preserve_devices               = options.value.preserve_devices
      security_descriptor_copy_flags = options.value.security_descriptor_copy_flags
      task_queueing                  = options.value.task_queueing
      transfer_mode                  = options.value.transfer_mode
      uid                            = options.value.uid
      verify_mode                    = options.value.verify_mode
    }
  }

  dynamic "schedule" {
    for_each = each.value.schedule != null ? [each.value.schedule] : []
    content {
      schedule_expression = schedule.value.schedule_expression
    }
  }

  dynamic "excludes" {
    for_each = each.value.excludes
    content {
      filter_type = excludes.value.filter_type
      value       = excludes.value.value
    }
  }

  dynamic "includes" {
    for_each = each.value.includes
    content {
      filter_type = includes.value.filter_type
      value       = includes.value.value
    }
  }

  dynamic "task_report_config" {
    for_each = each.value.task_report_config != null ? [each.value.task_report_config] : []
    content {
      output_type  = task_report_config.value.output_type
      report_level = task_report_config.value.report_level
      s3_destination {
        s3_bucket_arn     = task_report_config.value.s3_bucket_arn
        subdirectory      = task_report_config.value.s3_subdirectory
        bucket_access_role_arn = task_report_config.value.s3_bucket_access_role_arn
      }
    }
  }

  tags = merge(local.tags, { Task = each.key })
}
