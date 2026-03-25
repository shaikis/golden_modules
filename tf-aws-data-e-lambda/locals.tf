locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.function_name}" : var.function_name

  # Effective execution role ARN: BYO > module-created
  effective_role_arn = var.role_arn != null ? var.role_arn : (
    var.create_role ? aws_iam_role.lambda[0].arn : null
  )

  # Determine if this is a VPC-attached Lambda
  is_vpc = length(var.subnet_ids) > 0

  # Determine if this is a container image Lambda
  is_image = var.package_type == "Image"

  # Determine if EFS is attached
  has_efs = var.efs_access_point_arn != null && var.efs_local_mount_path != null

  # Determine if function URL is enabled
  has_function_url = var.create_function_url

  # Determine if provisioned concurrency is configured
  has_provisioned_concurrency = var.provisioned_concurrent_executions > 0

  # Managed policies to attach based on features
  vpc_policy = local.is_vpc && var.create_role ? [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ] : []

  xray_policy = var.tracing_mode == "Active" && var.create_role ? [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ] : []

  all_managed_policies = distinct(concat(var.managed_policy_arns, local.vpc_policy, local.xray_policy))

  # CloudWatch alarm actions — fall back to module SNS if alarm_actions not specified
  effective_alarm_actions = length(var.alarm_actions) > 0 ? var.alarm_actions : (
    var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  )

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-lambda"
  }
  tags = merge(local.default_tags, var.tags)

  effective_code_signing_config_arn = var.code_signing_config_arn != null ? var.code_signing_config_arn : (
    length(aws_lambda_code_signing_config.this) > 0 ? aws_lambda_code_signing_config.this[0].arn : null
  )

  # Merge: user-specified layers + Lambda Insights + module-created layers
  all_layers = concat(
    var.layers,
    var.enable_lambda_insights ? [data.aws_lambda_layer_version.insights[0].arn] : [],
    [for k, v in aws_lambda_layer_version.this : v.arn]
  )

  # Resolve which alias gets provisioned concurrency
  pc_alias_name = coalesce(
    var.provisioned_concurrency_alias,
    length(keys(var.aliases)) > 0 ? keys(var.aliases)[0] : "NONE"
  )

  effective_scheduler_role_arn = var.scheduler_role_arn != null ? var.scheduler_role_arn : (
    length(aws_iam_role.scheduler) > 0 ? aws_iam_role.scheduler[0].arn : null
  )
}
