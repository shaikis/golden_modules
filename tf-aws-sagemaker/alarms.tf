resource "aws_cloudwatch_metric_alarm" "endpoint_invocation_errors" {
  for_each = var.create_alarms ? var.endpoints : {}

  alarm_name          = "${local.name_prefix}${each.key}-invocation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Invocation4XXErrors"
  namespace           = "AWS/SageMaker"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "SageMaker endpoint ${each.key} 4XX errors exceeded threshold of 5 over 2 consecutive minutes."
  alarm_actions       = var.alarm_sns_arns
  ok_actions          = var.alarm_sns_arns

  dimensions = {
    EndpointName = each.key
    VariantName  = "AllTraffic"
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "endpoint_model_latency" {
  for_each = var.create_alarms ? var.endpoints : {}

  alarm_name          = "${local.name_prefix}${each.key}-model-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ModelLatency"
  namespace           = "AWS/SageMaker"
  period              = 60
  statistic           = "p99"
  threshold           = 5000 # 5 seconds in ms
  alarm_description   = "SageMaker endpoint ${each.key} p99 model latency exceeded 5 seconds."
  alarm_actions       = var.alarm_sns_arns
  ok_actions          = var.alarm_sns_arns

  dimensions = {
    EndpointName = each.key
    VariantName  = "AllTraffic"
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "endpoint_invocation_5xx_errors" {
  for_each = var.create_alarms ? var.endpoints : {}

  alarm_name          = "${local.name_prefix}${each.key}-invocation-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Invocation5XXErrors"
  namespace           = "AWS/SageMaker"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "SageMaker endpoint ${each.key} 5XX server-side errors detected."
  alarm_actions       = var.alarm_sns_arns
  ok_actions          = var.alarm_sns_arns

  dimensions = {
    EndpointName = each.key
    VariantName  = "AllTraffic"
  }

  tags = local.tags
}
