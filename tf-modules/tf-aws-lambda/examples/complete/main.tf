# =============================================================================
# Complete Lambda Example — All Options
# -----------------------------------------------------------------------------
# Demonstrates every available feature:
#   Simple Lambda   → set subnet_ids = []
#   VPC Lambda      → set subnet_ids + security_group_ids
#   Container image → set package_type = "Image", image_uri = "..."
#   Aliases         → set aliases = { live = {}, canary = {} }
#   Provisioned concurrency + auto-scaling
#   SQS / DynamoDB / Kinesis event source mappings
#   EventBridge Scheduler (cron/rate triggers)
#   Function URL (public or IAM-authenticated HTTPS)
#   Async destinations (success/failure → SQS/SNS/Lambda)
#   EFS mount
#   Lambda Layers (attach existing or create new)
#   Lambda Insights enhanced monitoring
#   CloudWatch alarms + dashboard
#   BYO IAM role or auto-create
#
# Usage:
#   terraform apply -var-file="dev.tfvars"
#   terraform apply -var-file="prod.tfvars"
# =============================================================================

provider "aws" {
  region = var.aws_region
}

module "lambda" {
  source = "../../"

  # ── Naming & Tagging ────────────────────────────────────────────────────────
  function_name = var.function_name
  name_prefix   = var.name_prefix
  environment   = var.environment
  project       = var.project
  owner         = var.owner
  cost_center   = var.cost_center
  description   = var.description
  tags          = var.tags

  # ── IAM Role ─────────────────────────────────────────────────────────────────
  # BYO Pattern:
  #   create_role = true  + role_arn = null  → module creates a new role  (default)
  #   create_role = false + role_arn = "arn" → reuse an existing role (no new role)
  create_role         = var.create_role
  role_arn            = var.role_arn
  managed_policy_arns = var.managed_policy_arns
  inline_policies     = var.inline_policies

  # ── Package & Code Source ────────────────────────────────────────────────────
  package_type      = var.package_type
  filename          = var.filename
  source_code_hash  = var.filename != null ? filebase64sha256(var.filename) : null
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version
  image_uri         = var.image_uri
  image_config      = var.image_config

  # ── Runtime & Hardware ───────────────────────────────────────────────────────
  handler                = var.handler
  runtime                = var.runtime
  architectures          = var.architectures
  memory_size            = var.memory_size
  timeout                = var.timeout
  ephemeral_storage_size = var.ephemeral_storage_size
  publish                = var.publish
  layers                 = var.layers
  snap_start             = var.snap_start

  # ── VPC (simple = no subnets, VPC = provide subnets) ─────────────────────────
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  # ── EFS Mount ────────────────────────────────────────────────────────────────
  efs_access_point_arn = var.efs_access_point_arn
  efs_local_mount_path = var.efs_local_mount_path

  # ── Environment & Encryption ─────────────────────────────────────────────────
  environment_variables = var.environment_variables
  kms_key_arn           = var.kms_key_arn

  # ── Concurrency ──────────────────────────────────────────────────────────────
  reserved_concurrent_executions    = var.reserved_concurrent_executions
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  provisioned_concurrency_alias     = var.provisioned_concurrency_alias

  # ── Concurrency Auto-Scaling ─────────────────────────────────────────────────
  enable_autoscaling             = var.enable_autoscaling
  autoscaling_min_capacity       = var.autoscaling_min_capacity
  autoscaling_max_capacity       = var.autoscaling_max_capacity
  autoscaling_target_utilization = var.autoscaling_target_utilization
  autoscaling_scale_in_cooldown  = var.autoscaling_scale_in_cooldown
  autoscaling_scale_out_cooldown = var.autoscaling_scale_out_cooldown

  # ── Aliases ───────────────────────────────────────────────────────────────────
  aliases = var.aliases

  # ── Tracing ───────────────────────────────────────────────────────────────────
  tracing_mode = var.tracing_mode

  # ── Dead Letter & Async Destinations ─────────────────────────────────────────
  dead_letter_target_arn             = var.dead_letter_target_arn
  async_on_success_destination_arn   = var.async_on_success_destination_arn
  async_on_failure_destination_arn   = var.async_on_failure_destination_arn
  async_maximum_event_age_in_seconds = var.async_maximum_event_age_in_seconds
  async_maximum_retry_attempts       = var.async_maximum_retry_attempts

  # ── Function URL ─────────────────────────────────────────────────────────────
  create_function_url      = var.create_function_url
  function_url_auth_type   = var.function_url_auth_type
  function_url_invoke_mode = var.function_url_invoke_mode
  function_url_cors        = var.function_url_cors

  # ── Triggers ─────────────────────────────────────────────────────────────────
  allowed_triggers = var.allowed_triggers

  # ── Event Source Mappings ─────────────────────────────────────────────────────
  event_source_mappings = var.event_source_mappings

  # ── EventBridge Schedules ─────────────────────────────────────────────────────
  schedules          = var.schedules
  scheduler_role_arn = var.scheduler_role_arn

  # ── Lambda Layers (create new) ────────────────────────────────────────────────
  lambda_layers = var.lambda_layers

  # ── Code Signing ─────────────────────────────────────────────────────────────
  code_signing_config_arn                 = var.code_signing_config_arn
  allowed_publishers_signing_profile_arns = var.allowed_publishers_signing_profile_arns

  # ── CloudWatch Logs ───────────────────────────────────────────────────────────
  log_retention_days    = var.log_retention_days
  log_kms_key_id        = var.log_kms_key_id
  log_format            = var.log_format
  application_log_level = var.application_log_level
  system_log_level      = var.system_log_level

  # ── CloudWatch Alarms ─────────────────────────────────────────────────────────
  create_cloudwatch_alarms    = var.create_cloudwatch_alarms
  alarm_sns_topic_arn         = var.alarm_sns_topic_arn
  alarm_actions               = var.alarm_actions
  alarm_error_threshold       = var.alarm_error_threshold
  alarm_throttle_threshold    = var.alarm_throttle_threshold
  alarm_duration_threshold_ms = var.alarm_duration_threshold_ms
  alarm_evaluation_periods    = var.alarm_evaluation_periods
  alarm_period_seconds        = var.alarm_period_seconds

  # ── CloudWatch Dashboard ──────────────────────────────────────────────────────
  create_cloudwatch_dashboard = var.create_cloudwatch_dashboard
  dashboard_name              = var.dashboard_name

  # ── Lambda Insights ───────────────────────────────────────────────────────────
  enable_lambda_insights  = var.enable_lambda_insights
  lambda_insights_version = var.lambda_insights_version
}
