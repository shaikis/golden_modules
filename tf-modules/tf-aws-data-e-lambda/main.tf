# ── Data Sources ──────────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Lambda Insights layer ARN (AWS-managed, region-specific)
data "aws_lambda_layer_version" "insights" {
  count      = var.enable_lambda_insights ? 1 : 0
  layer_name = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension"
  version    = var.lambda_insights_version
}

# ── IAM Execution Role ────────────────────────────────────────────────────────
# BYO pattern:
#   var.role_arn provided        → use it, skip creation
#   var.role_arn = null (default) → create new role (when create_role = true)
resource "aws_iam_role" "lambda" {
  count = var.create_role && var.role_arn == null ? 1 : 0

  name = "${local.name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  for_each = var.create_role && var.role_arn == null ? toset(local.all_managed_policies) : toset([])

  role       = aws_iam_role.lambda[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.create_role && var.role_arn == null ? var.inline_policies : {}

  name   = each.key
  role   = aws_iam_role.lambda[0].id
  policy = each.value
}

# Auto-attach EFS permissions when EFS mount is configured
resource "aws_iam_role_policy" "efs" {
  count = var.create_role && var.role_arn == null && local.has_efs ? 1 : 0

  name = "${local.name}-efs-access"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      Resource = var.efs_access_point_arn
    }]
  })
}

# ── Code Signing Config ───────────────────────────────────────────────────────
resource "aws_lambda_code_signing_config" "this" {
  count = length(var.allowed_publishers_signing_profile_arns) > 0 ? 1 : 0

  description = "${local.name} code signing config"

  allowed_publishers {
    signing_profile_version_arns = var.allowed_publishers_signing_profile_arns
  }

  policies {
    untrusted_artifact_on_deployment = var.signing_untrusted_artifact_on_deployment
  }
}

locals {
  effective_code_signing_config_arn = var.code_signing_config_arn != null ? var.code_signing_config_arn : (
    length(aws_lambda_code_signing_config.this) > 0 ? aws_lambda_code_signing_config.this[0].arn : null
  )
}

# ── Lambda Layers (create new) ────────────────────────────────────────────────
resource "aws_lambda_layer_version" "this" {
  for_each = var.lambda_layers

  layer_name               = "${local.name}-${each.key}"
  description              = each.value.description
  filename                 = each.value.filename
  s3_bucket                = each.value.s3_bucket
  s3_key                   = each.value.s3_key
  s3_object_version        = each.value.s3_object_version
  compatible_runtimes      = each.value.compatible_runtimes
  compatible_architectures = each.value.compatible_architectures
  license_info             = each.value.license_info
  source_code_hash         = each.value.source_code_hash

  lifecycle {
    create_before_destroy = true
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────
# Created before the function so logs are retained even if function is deleted
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = local.tags
}

# ── Lambda Function ───────────────────────────────────────────────────────────
locals {
  # Merge: user-specified layers + Lambda Insights + module-created layers
  all_layers = concat(
    var.layers,
    var.enable_lambda_insights ? [data.aws_lambda_layer_version.insights[0].arn] : [],
    [for k, v in aws_lambda_layer_version.this : v.arn]
  )
}

resource "aws_lambda_function" "this" {
  function_name = local.name
  description   = coalesce(var.description, "${local.name} Lambda function")
  role          = local.effective_role_arn

  # ── Package type ────────────────────────────────────────────────────────────
  package_type  = var.package_type
  architectures = var.architectures
  memory_size   = var.memory_size
  timeout       = var.timeout
  publish       = var.publish
  layers        = local.all_layers

  reserved_concurrent_executions = var.reserved_concurrent_executions
  kms_key_arn                    = var.kms_key_arn
  code_signing_config_arn        = local.effective_code_signing_config_arn

  # ── Zip source (local file or S3) ───────────────────────────────────────────
  filename          = var.package_type == "Zip" ? var.filename : null
  source_code_hash  = var.package_type == "Zip" ? var.source_code_hash : null
  s3_bucket         = var.package_type == "Zip" ? var.s3_bucket : null
  s3_key            = var.package_type == "Zip" ? var.s3_key : null
  s3_object_version = var.package_type == "Zip" ? var.s3_object_version : null

  # ── Container image source ──────────────────────────────────────────────────
  image_uri = var.package_type == "Image" ? var.image_uri : null

  # ── Runtime (Zip only) ──────────────────────────────────────────────────────
  handler = var.package_type == "Zip" ? var.handler : null
  runtime = var.package_type == "Zip" ? var.runtime : null

  # ── Ephemeral storage (/tmp) ────────────────────────────────────────────────
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  # ── Container image overrides ───────────────────────────────────────────────
  dynamic "image_config" {
    for_each = var.package_type == "Image" && var.image_config != null ? [var.image_config] : []
    content {
      command           = image_config.value.command
      entry_point       = image_config.value.entry_point
      working_directory = image_config.value.working_directory
    }
  }

  # ── Environment variables ───────────────────────────────────────────────────
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # ── VPC (subnet-attached Lambda) ────────────────────────────────────────────
  dynamic "vpc_config" {
    for_each = local.is_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  # ── EFS mount ───────────────────────────────────────────────────────────────
  dynamic "file_system_config" {
    for_each = local.has_efs ? [1] : []
    content {
      arn              = var.efs_access_point_arn
      local_mount_path = var.efs_local_mount_path
    }
  }

  # ── X-Ray tracing ───────────────────────────────────────────────────────────
  tracing_config {
    mode = var.tracing_mode
  }

  # ── Dead letter queue ───────────────────────────────────────────────────────
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # ── SnapStart (Java 11+) ────────────────────────────────────────────────────
  dynamic "snap_start" {
    for_each = var.snap_start != "None" ? [1] : []
    content {
      apply_on = var.snap_start
    }
  }

  # ── Structured logging (JSON format) ────────────────────────────────────────
  dynamic "logging_config" {
    for_each = var.log_format == "JSON" ? [1] : []
    content {
      log_format            = var.log_format
      log_group             = aws_cloudwatch_log_group.this.name
      application_log_level = var.application_log_level
      system_log_level      = var.system_log_level
    }
  }

  tags = local.tags

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.lambda,
  ]
}

# ── Async Event Invoke Config (destinations + retry) ─────────────────────────
resource "aws_lambda_function_event_invoke_config" "this" {
  count = (
    var.async_on_success_destination_arn != null ||
    var.async_on_failure_destination_arn != null
  ) ? 1 : 0

  function_name                = aws_lambda_function.this.function_name
  maximum_event_age_in_seconds = var.async_maximum_event_age_in_seconds
  maximum_retry_attempts       = var.async_maximum_retry_attempts

  destination_config {
    dynamic "on_success" {
      for_each = var.async_on_success_destination_arn != null ? [1] : []
      content {
        destination = var.async_on_success_destination_arn
      }
    }
    dynamic "on_failure" {
      for_each = var.async_on_failure_destination_arn != null ? [1] : []
      content {
        destination = var.async_on_failure_destination_arn
      }
    }
  }
}

# ── Aliases ───────────────────────────────────────────────────────────────────
resource "aws_lambda_alias" "this" {
  for_each = var.publish ? var.aliases : {}

  name             = each.key
  description      = each.value.description
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version

  dynamic "routing_config" {
    for_each = each.value.routing_weight != null && each.value.additional_version != null ? [1] : []
    content {
      additional_version_weights = {
        (each.value.additional_version) = each.value.routing_weight
      }
    }
  }

  lifecycle {
    ignore_changes = [function_version]
  }
}

# ── Provisioned Concurrency ───────────────────────────────────────────────────
locals {
  # Resolve which alias gets provisioned concurrency
  pc_alias_name = coalesce(
    var.provisioned_concurrency_alias,
    length(keys(var.aliases)) > 0 ? keys(var.aliases)[0] : "NONE"
  )
}

resource "aws_lambda_provisioned_concurrency_config" "this" {
  count = local.has_provisioned_concurrency && local.pc_alias_name != "NONE" ? 1 : 0

  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = aws_lambda_alias.this[local.pc_alias_name].name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions

  depends_on = [aws_lambda_alias.this]
}

# ── Provisioned Concurrency Auto-Scaling ──────────────────────────────────────
resource "aws_appautoscaling_target" "lambda" {
  count = var.enable_autoscaling && local.pc_alias_name != "NONE" ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "function:${aws_lambda_function.this.function_name}:${aws_lambda_alias.this[local.pc_alias_name].name}"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  service_namespace  = "lambda"

  depends_on = [aws_lambda_provisioned_concurrency_config.this]
}

resource "aws_appautoscaling_policy" "lambda" {
  count = var.enable_autoscaling && local.pc_alias_name != "NONE" ? 1 : 0

  name               = "${local.name}-pc-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.lambda[0].resource_id
  scalable_dimension = aws_appautoscaling_target.lambda[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.lambda[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_target_utilization
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
  }
}

# ── Function URL ──────────────────────────────────────────────────────────────
resource "aws_lambda_function_url" "this" {
  count = var.create_function_url ? 1 : 0

  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type
  invoke_mode        = var.function_url_invoke_mode

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }
}

# Allow unauthenticated invocations when auth type = NONE
resource "aws_lambda_permission" "function_url_public" {
  count = var.create_function_url && var.function_url_auth_type == "NONE" ? 1 : 0

  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# ── Resource-based Permissions (triggers) ─────────────────────────────────────
resource "aws_lambda_permission" "this" {
  for_each = var.allowed_triggers

  statement_id   = each.key
  action         = each.value.action
  function_name  = aws_lambda_function.this.function_name
  qualifier      = each.value.qualifier
  principal      = each.value.principal
  source_arn     = each.value.source_arn
  source_account = each.value.source_account
}

# ── Event Source Mappings (SQS, DynamoDB, Kinesis, MSK, MQ) ──────────────────
resource "aws_lambda_event_source_mapping" "this" {
  for_each = var.event_source_mappings

  event_source_arn                   = each.value.event_source_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = each.value.batch_size
  maximum_batching_window_in_seconds = each.value.maximum_batching_window_in_seconds
  starting_position                  = each.value.starting_position
  starting_position_timestamp        = each.value.starting_position_timestamp
  enabled                            = each.value.enabled
  bisect_batch_on_function_error     = each.value.bisect_batch_on_function_error
  maximum_retry_attempts             = each.value.maximum_retry_attempts
  tumbling_window_in_seconds         = each.value.tumbling_window_in_seconds
  parallelization_factor             = each.value.parallelization_factor
  function_response_types            = each.value.function_response_types

  dynamic "filter_criteria" {
    for_each = length(each.value.filter_criteria) > 0 ? [1] : []
    content {
      dynamic "filter" {
        for_each = each.value.filter_criteria
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }

  dynamic "destination_config" {
    for_each = each.value.destination_config != null ? [each.value.destination_config] : []
    content {
      dynamic "on_failure" {
        for_each = destination_config.value.on_failure_destination_arn != null ? [1] : []
        content {
          destination_arn = destination_config.value.on_failure_destination_arn
        }
      }
    }
  }
}

# ── EventBridge Scheduler ─────────────────────────────────────────────────────
# Auto-create a minimal scheduler IAM role when schedules are defined
resource "aws_iam_role" "scheduler" {
  count = length(var.schedules) > 0 && var.scheduler_role_arn == null ? 1 : 0

  name = "${local.name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  count = length(var.schedules) > 0 && var.scheduler_role_arn == null ? 1 : 0

  name = "${local.name}-scheduler-invoke"
  role = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.this.arn,
        "${aws_lambda_function.this.arn}:*"
      ]
    }]
  })
}

locals {
  effective_scheduler_role_arn = var.scheduler_role_arn != null ? var.scheduler_role_arn : (
    length(aws_iam_role.scheduler) > 0 ? aws_iam_role.scheduler[0].arn : null
  )
}

resource "aws_scheduler_schedule" "this" {
  for_each = var.schedules

  name        = "${local.name}-${each.key}"
  description = each.value.description
  state       = each.value.state

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone

  flexible_time_window {
    mode                      = each.value.flexible_time_window_minutes > 0 ? "FLEXIBLE" : "OFF"
    maximum_window_in_minutes = each.value.flexible_time_window_minutes > 0 ? each.value.flexible_time_window_minutes : null
  }

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = local.effective_scheduler_role_arn
    input    = each.value.input

    dynamic "retry_policy" {
      for_each = each.value.retry_maximum_retry_attempts != null ? [1] : []
      content {
        maximum_event_age_in_seconds = each.value.retry_maximum_event_age_in_seconds
        maximum_retry_attempts       = each.value.retry_maximum_retry_attempts
      }
    }
  }
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "errors" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name}-errors"
  alarm_description   = "Lambda errors >= ${var.alarm_error_threshold} for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions
  ok_actions    = local.effective_alarm_actions

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name}-throttles"
  alarm_description   = "Lambda throttles >= ${var.alarm_throttle_threshold} for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_throttle_threshold
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions
  ok_actions    = local.effective_alarm_actions

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  count = var.create_cloudwatch_alarms && var.alarm_duration_threshold_ms > 0 ? 1 : 0

  alarm_name          = "${local.name}-duration"
  alarm_description   = "Lambda avg duration >= ${var.alarm_duration_threshold_ms}ms for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alarm_duration_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions
  ok_actions    = local.effective_alarm_actions

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "concurrent_executions" {
  count = var.create_cloudwatch_alarms && var.reserved_concurrent_executions > 0 ? 1 : 0

  alarm_name          = "${local.name}-concurrency"
  alarm_description   = "Lambda concurrency approaching reserved limit (${var.reserved_concurrent_executions}) for ${local.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = floor(var.reserved_concurrent_executions * 0.8)
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.this.function_name }

  alarm_actions = local.effective_alarm_actions

  tags = local.tags
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_cloudwatch_dashboard ? 1 : 0

  dashboard_name = coalesce(var.dashboard_name, "${local.name}-lambda-dashboard")

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "## Lambda: **${local.name}**\nRegion: `${data.aws_region.current.name}` | Environment: `${var.environment}` | Runtime: `${var.runtime}` | Memory: `${var.memory_size} MB`"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          title   = "Invocations & Errors"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.this.function_name, { stat = "Sum", color = "#2ca02c", label = "Invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.this.function_name, { stat = "Sum", color = "#d62728", label = "Errors" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          title = "Duration (ms)"
          view  = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.this.function_name, { stat = "Average", label = "Avg" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "Maximum", label = "Max" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          title = "Throttles & Concurrency"
          view  = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Throttles", "FunctionName", aws_lambda_function.this.function_name, { stat = "Sum", color = "#ff7f0e", label = "Throttles" }],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", aws_lambda_function.this.function_name, { stat = "Maximum", color = "#1f77b4", label = "Concurrent" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title = "Cold Starts (Init Duration)"
          view  = "timeSeries"
          metrics = [
            ["AWS/Lambda", "InitDuration", "FunctionName", aws_lambda_function.this.function_name, { stat = "Average", label = "Avg Init" }],
            ["...", { stat = "Maximum", label = "Max Init" }]
          ]
          period = 60
          region = data.aws_region.current.name
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Recent Errors"
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.this.name}' | filter @message like /(?i)error|exception/ | sort @timestamp desc | limit 20"
          region = data.aws_region.current.name
        }
      }
    ]
  })
}
