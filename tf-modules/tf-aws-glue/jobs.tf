# ---------------------------------------------------------------------------
# Glue ETL Jobs
# ---------------------------------------------------------------------------

locals {
  # Determine the effective IAM role ARN for each job.
  job_role_arns = {
    for k, v in var.jobs :
    k => coalesce(v.role_arn, var.create_iam_role ? aws_iam_role.glue_service[0].arn : "")
  }

  # Merge caller-supplied default_arguments with the mandatory platform args.
  # Callers can still override any of these by including the same key in their
  # default_arguments map — the caller map is merged last.
  job_default_arguments = {
    for k, v in var.jobs :
    k => merge(
      {
        "--enable-metrics"                   = "true"
        "--enable-continuous-cloudwatch-log" = "true"
        "--enable-continuous-log-filter"     = "true"
        "--job-bookmark-option"              = v.bookmark_option != null ? v.bookmark_option : "job-bookmark-enable"
        "--enable-spark-ui"                  = "true"
        "--spark-event-logs-path"            = "s3://aws-glue-assets-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/sparkHistoryLogs/"
        "--TempDir"                          = "s3://aws-glue-assets-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/temporary/"
        "--enable-glue-datacatalog"          = "true"
      },
      v.default_arguments != null ? v.default_arguments : {}
    )
  }
}

resource "aws_glue_job" "this" {
  for_each = var.jobs

  name                   = "${var.name_prefix}${each.key}"
  description            = each.value.description
  role_arn               = local.job_role_arns[each.key]
  glue_version           = each.value.glue_version != null ? each.value.glue_version : "4.0"
  max_retries            = each.value.max_retries != null ? each.value.max_retries : 1
  timeout                = each.value.timeout != null ? each.value.timeout : 2880
  execution_class        = each.value.execution_class != null ? each.value.execution_class : "STANDARD"
  connections            = each.value.connections != null ? each.value.connections : []
  security_configuration = each.value.security_configuration
  default_arguments      = local.job_default_arguments[each.key]

  non_overridable_arguments = each.value.non_overridable_arguments != null ? each.value.non_overridable_arguments : {}

  # Worker / capacity settings — not applicable to pythonshell
  worker_type       = each.value.job_type != "pythonshell" ? each.value.worker_type : null
  number_of_workers = each.value.job_type != "pythonshell" ? each.value.number_of_workers : null

  command {
    name            = each.value.job_type != null ? each.value.job_type : "glueetl"
    script_location = each.value.script_location
    python_version  = each.value.python_version != null ? each.value.python_version : "3"
  }

  execution_property {
    max_concurrent_runs = each.value.max_concurrent_runs != null ? each.value.max_concurrent_runs : 1
  }

  dynamic "notification_property" {
    for_each = each.value.notify_delay_after != null ? [each.value.notify_delay_after] : []
    content {
      notify_delay_after = notification_property.value
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}${each.key}" })

  depends_on = [
    aws_iam_role_policy_attachment.glue_managed,
    aws_iam_role_policy.glue_inline,
  ]
}
