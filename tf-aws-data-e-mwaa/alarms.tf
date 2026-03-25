# ── CloudWatch Alarms for MWAA ────────────────────────────────────────────────
# Gated by create_alarms = true

# ── QueuedTasks > threshold ───────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_queued_tasks" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-queued-tasks"
  alarm_description   = "MWAA environment ${each.key}: tasks waiting in queue exceed threshold. Consider scaling workers."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "QueuedTasks"
  namespace           = "AmazonMWAA"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.alarm_queued_tasks_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    Function    = "Executor"
    Environment = "${var.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}

# ── RunningTasks > 0 (monitoring active tasks) ────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_running_tasks" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-running-tasks"
  alarm_description   = "MWAA environment ${each.key}: tasks are actively running."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTasks"
  namespace           = "AmazonMWAA"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    Function    = "Executor"
    Environment = "${var.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}

# ── SchedulerHeartbeat < 1 (scheduler down — critical) ───────────────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_scheduler_heartbeat" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-scheduler-heartbeat"
  alarm_description   = "CRITICAL: MWAA environment ${each.key} scheduler heartbeat has stopped. Scheduler may be down."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "SchedulerHeartbeat"
  namespace           = "AmazonMWAA"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    Function    = "Scheduler"
    Environment = "${var.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}

# ── TasksPending > threshold ──────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_tasks_pending" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-tasks-pending"
  alarm_description   = "MWAA environment ${each.key}: pending tasks exceed threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TasksPending"
  namespace           = "AmazonMWAA"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.alarm_pending_tasks_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    Function    = "Executor"
    Environment = "${var.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}

# ── WorkerOnlineTriggerCount monitoring ───────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_worker_online" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-worker-online-count"
  alarm_description   = "MWAA environment ${each.key}: no online workers detected."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "WorkersOnline"
  namespace           = "AmazonMWAA"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    Function    = "Worker"
    Environment = "${var.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}

# ── DAGFileProcessingTotalParseTime > threshold (slow DAG parsing) ────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_dag_parse_time" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-dag-parse-time"
  alarm_description   = "MWAA environment ${each.key}: DAG parsing time exceeds threshold. Check for slow DAGs."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DAGFileProcessingTotalParseTime"
  namespace           = "AmazonMWAA"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.alarm_dag_parse_time_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    Function    = "DagProcessor"
    Environment = "${var.name_prefix}${each.key}"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}

# ── DeadLetterQueueSize > 0 (failed task events) ─────────────────────────────

resource "aws_cloudwatch_metric_alarm" "mwaa_dlq_size" {
  for_each = var.create_alarms ? var.environments : {}

  alarm_name          = "${var.name_prefix}${each.key}-dead-letter-queue"
  alarm_description   = "MWAA environment ${each.key}: messages in dead letter queue. Failed task events require investigation."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfMessagesSent"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = "airflow-celery-${var.name_prefix}${each.key}-dead-letter"
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.tags, each.value.tags)
}
