# ── Provisioned Concurrency ───────────────────────────────────────────────────
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
