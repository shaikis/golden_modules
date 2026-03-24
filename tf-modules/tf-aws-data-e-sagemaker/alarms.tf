# ---------------------------------------------------------------------------
# CloudWatch Alarms — SageMaker Endpoints
# Gated by create_alarms = true
# ---------------------------------------------------------------------------

locals {
  endpoint_alarm_map = var.create_alarms ? {
    for endpoint_key, endpoint_val in var.endpoints :
    endpoint_key => endpoint_key
  } : {}
}

# ── Invocation Rate ──────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "invocations" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-invocations-low"
  alarm_description   = "SageMaker endpoint ${each.key} has received zero invocations."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Invocations"
  namespace           = "AWS/SageMaker"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-invocations-low" })
}

# ── Model Latency p99 ────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "model_latency_p99" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-model-latency-p99"
  alarm_description   = "SageMaker endpoint ${each.key} p99 ModelLatency exceeds ${var.alarm_model_latency_p99_ms}ms."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ModelLatency"
  namespace           = "AWS/SageMaker"
  period              = var.alarm_period_seconds
  extended_statistic  = "p99"
  threshold           = var.alarm_model_latency_p99_ms * 1000
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-model-latency-p99" })
}

# ── 4XX Errors ────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "errors_4xx" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-4xx-errors"
  alarm_description   = "SageMaker endpoint ${each.key} 4XX error count exceeds threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Invocation4XXErrors"
  namespace           = "AWS/SageMaker"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_rate_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-4xx-errors" })
}

# ── 5XX Errors (Critical) ────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "errors_5xx" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-5xx-errors"
  alarm_description   = "CRITICAL: SageMaker endpoint ${each.key} 5XX model serving failures exceed threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Invocation5XXErrors"
  namespace           = "AWS/SageMaker"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_rate_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-5xx-errors" })
}

# ── Invocation Model Errors ───────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "invocation_model_errors" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-invocation-model-errors"
  alarm_description   = "SageMaker endpoint ${each.key} InvocationModelErrors exceed threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "InvocationModelErrors"
  namespace           = "AWS/SageMaker"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_rate_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-invocation-model-errors" })
}

# ── CPU Utilization ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-cpu-utilization"
  alarm_description   = "SageMaker endpoint ${each.key} CPU utilization exceeds ${var.alarm_cpu_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-cpu-utilization" })
}

# ── Memory Utilization ────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-memory-utilization"
  alarm_description   = "SageMaker endpoint ${each.key} memory utilization exceeds ${var.alarm_memory_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-memory-utilization" })
}

# ── Disk Utilization ──────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "disk_utilization" {
  for_each = local.endpoint_alarm_map

  alarm_name          = "${each.key}-disk-utilization"
  alarm_description   = "SageMaker endpoint ${each.key} disk utilization exceeds ${var.alarm_disk_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DiskUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alarm_disk_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.this[each.key].name
    VariantName  = "AllTraffic"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, { Name = "${each.key}-disk-utilization" })
}
