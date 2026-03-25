# ── Lambda Function ───────────────────────────────────────────────────────────
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
