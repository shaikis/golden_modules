# ── MWAA Environments ─────────────────────────────────────────────────────────

resource "aws_mwaa_environment" "this" {
  for_each = var.environments

  name              = "${var.name_prefix}${each.key}"
  airflow_version   = each.value.airflow_version
  environment_class = each.value.environment_class
  max_workers       = each.value.max_workers
  min_workers       = each.value.min_workers
  schedulers        = each.value.schedulers

  source_bucket_arn    = each.value.source_bucket_arn
  dag_s3_path          = each.value.dag_s3_path
  requirements_s3_path = each.value.requirements_s3_path
  plugins_s3_path      = each.value.plugins_s3_path

  requirements_s3_object_version   = each.value.requirements_s3_object_version
  plugins_s3_object_version        = each.value.plugins_s3_object_version
  startup_script_s3_path           = each.value.startup_script_s3_path
  startup_script_s3_object_version = each.value.startup_script_s3_object_version

  execution_role_arn = coalesce(
    each.value.execution_role_arn,
    var.role_arn,
    try(aws_iam_role.mwaa[0].arn, null),
  )

  kms_key = coalesce(each.value.kms_key, var.kms_key_arn, null)

  webserver_access_mode           = each.value.webserver_access_mode
  weekly_maintenance_window_start = each.value.weekly_maintenance_window_start

  airflow_configuration_options = each.value.airflow_configuration_options

  network_configuration {
    subnet_ids         = each.value.subnet_ids
    security_group_ids = each.value.security_group_ids
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = each.value.dag_processing_logs_level
    }
    scheduler_logs {
      enabled   = true
      log_level = each.value.scheduler_logs_level
    }
    task_logs {
      enabled   = true
      log_level = each.value.task_logs_level
    }
    webserver_logs {
      enabled   = true
      log_level = each.value.webserver_logs_level
    }
    worker_logs {
      enabled   = true
      log_level = each.value.worker_logs_level
    }
  }

  tags = merge(var.tags, each.value.tags)

  lifecycle {
    ignore_changes = [
      # Prevent forced replacement when MWAA updates the service-linked role
      execution_role_arn,
    ]
  }
}
