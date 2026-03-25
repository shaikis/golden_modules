# ---------------------------------------------------------------------------
# CloudWatch Alarms — per DynamoDB table
# ---------------------------------------------------------------------------

locals {
  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  # All standard (non-global) tables for alarms
  alarm_tables = var.create_alarms ? var.tables : {}

  # All global tables for replication latency alarms
  alarm_global_tables = var.create_alarms ? var.global_tables : {}

  # Provisioned tables needing consumed-capacity alarms
  provisioned_alarm_tables = {
    for k, v in local.alarm_tables : k => v
    if v.billing_mode == "PROVISIONED"
  }
}

# ---------------------------------------------------------------------------
# SystemErrors — DynamoDB internal errors
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "system_errors" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-system-errors"
  alarm_description   = "DynamoDB system errors on table ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# UserErrors — client-side errors (ValidationException etc.)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "user_errors" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-user-errors"
  alarm_description   = "DynamoDB user errors on table ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# ReadThrottleEvents
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "read_throttle" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-read-throttle"
  alarm_description   = "Read throttle events on ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# WriteThrottleEvents
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "write_throttle" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-write-throttle"
  alarm_description   = "Write throttle events on ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# ConsumedReadCapacityUnits — PROVISIONED tables only
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "consumed_read_capacity" {
  for_each = local.provisioned_alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-consumed-rcu"
  alarm_description   = "Consumed RCU approaching provisioned limit for ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  # Alert at 80% of provisioned capacity per minute
  threshold          = (each.value.read_capacity != null ? each.value.read_capacity : 5) * 60 * 0.8
  treat_missing_data = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# ConsumedWriteCapacityUnits — PROVISIONED tables only
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "consumed_write_capacity" {
  for_each = local.provisioned_alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-consumed-wcu"
  alarm_description   = "Consumed WCU approaching provisioned limit for ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = (each.value.write_capacity != null ? each.value.write_capacity : 5) * 60 * 0.8
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# SuccessfulRequestLatency — p99 high latency
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "latency_get" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-latency-GetItem"
  alarm_description   = "High GetItem p99 latency on ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "SuccessfulRequestLatency"
  namespace           = "AWS/DynamoDB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = var.latency_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
    Operation = "GetItem"
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_cloudwatch_metric_alarm" "latency_query" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-latency-Query"
  alarm_description   = "High Query p99 latency on ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "SuccessfulRequestLatency"
  namespace           = "AWS/DynamoDB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = var.latency_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
    Operation = "Query"
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_cloudwatch_metric_alarm" "latency_put" {
  for_each = local.alarm_tables

  alarm_name          = "${var.name_prefix}-${each.key}-latency-PutItem"
  alarm_description   = "High PutItem p99 latency on ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "SuccessfulRequestLatency"
  namespace           = "AWS/DynamoDB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = var.latency_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.this[each.key].name
    Operation = "PutItem"
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# OnlineIndexPercentageProgress — GSI build stuck
# ---------------------------------------------------------------------------

locals {
  # Flatten table → GSI pairs for index progress alarms
  gsi_alarm_pairs = merge([
    for table_key, table in local.alarm_tables : {
      for gsi in table.global_secondary_indexes :
      "${table_key}__${gsi.name}" => {
        table_key  = table_key
        table_name = "${var.name_prefix}-${table_key}"
        gsi_name   = gsi.name
      }
    }
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "gsi_build_progress" {
  for_each = local.gsi_alarm_pairs

  alarm_name          = "${each.value.table_name}-${each.value.gsi_name}-index-progress"
  alarm_description   = "GSI ${each.value.gsi_name} build may be stuck on ${each.value.table_name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "OnlineIndexPercentageProgress"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName                = aws_dynamodb_table.this[each.value.table_key].name
    GlobalSecondaryIndexName = each.value.gsi_name
  }

  alarm_actions = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# ---------------------------------------------------------------------------
# ReplicationLatency — Global Tables
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "replication_latency" {
  for_each = local.alarm_global_tables

  alarm_name          = "${var.name_prefix}-${each.key}-replication-latency"
  alarm_description   = "Global table replication latency high for ${var.name_prefix}-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.replication_latency_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName       = aws_dynamodb_table.global[each.key].name
    ReceivingRegion = each.value.replicas[0].region_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = merge(var.tags, { ManagedBy = "terraform" })
}
