###############################################################################
# Complete example: tf-aws-cloudwatch module
#
# Demonstrates ALL supported features:
#   - SNS topic creation with email + OpsGenie subscriptions
#   - Lambda metric alarms (errors, throttles, duration)
#   - RDS metric alarms (CPU, connections, storage)
#   - SQS metric alarms (queue depth, message age)
#   - ASG alarms (CPU high/low, maxed out, below minimum)
#   - AWS Backup failure alarms
#   - Log metric filter with alarm
#   - Anomaly detection on Lambda duration
#   - Composite alarm (Lambda errors AND SQS message age)
#   - Dashboard with Lambda + RDS + SQS + ASG widgets
#   - EventBridge routing for ALARM state changes
###############################################################################

module "cloudwatch" {
  source = "../../"

  # ── Naming & Tagging ────────────────────────────────────────────────────────
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  # ── SNS Topic ───────────────────────────────────────────────────────────────
  # Create a new SNS topic; set sns_topic_arn to reuse an existing one
  create_sns_topic = var.create_sns_topic
  sns_topic_arn    = var.sns_topic_arn
  sns_kms_key_id   = var.sns_kms_key_id

  # ── Notification Integrations ────────────────────────────────────────────────
  email_endpoints        = var.email_endpoints
  opsgenie_endpoint_url  = var.opsgenie_endpoint_url
  pagerduty_endpoint_url = var.pagerduty_endpoint_url
  alarm_sqs_queue_arn    = var.alarm_sqs_queue_arn

  # ── Generic Metric Alarms ────────────────────────────────────────────────────
  # Works with any AWS namespace or custom metrics
  metric_alarms = {

    # Lambda alarms
    lambda_errors = {
      namespace          = "AWS/Lambda"
      metric_name        = "Errors"
      dimensions         = { FunctionName = var.lambda_function_name }
      statistic          = "Sum"
      threshold          = 1
      period             = 60
      evaluation_periods = 1
      treat_missing_data = "notBreaching"
      alarm_description  = "Lambda function ${var.lambda_function_name} is throwing errors"
      severity           = "critical"
    }

    lambda_throttles = {
      namespace          = "AWS/Lambda"
      metric_name        = "Throttles"
      dimensions         = { FunctionName = var.lambda_function_name }
      statistic          = "Sum"
      threshold          = 5
      period             = 60
      evaluation_periods = 2
      treat_missing_data = "notBreaching"
      alarm_description  = "Lambda function ${var.lambda_function_name} is being throttled"
      severity           = "warning"
    }

    lambda_duration_p99 = {
      namespace           = "AWS/Lambda"
      metric_name         = "Duration"
      dimensions          = { FunctionName = var.lambda_function_name }
      statistic           = "p99"
      threshold           = 25000
      period              = 300
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      treat_missing_data  = "notBreaching"
      alarm_description   = "Lambda p99 duration exceeds 25s — approaching 30s timeout"
      severity            = "warning"
    }

    # RDS alarms
    rds_cpu_high = {
      namespace          = "AWS/RDS"
      metric_name        = "CPUUtilization"
      dimensions         = { DBInstanceIdentifier = var.rds_instance_id }
      statistic          = "Average"
      threshold          = 80
      period             = 300
      evaluation_periods = 2
      treat_missing_data = "notBreaching"
      alarm_description  = "RDS ${var.rds_instance_id} CPU is above 80%"
      severity           = "critical"
    }

    rds_connections_high = {
      namespace          = "AWS/RDS"
      metric_name        = "DatabaseConnections"
      dimensions         = { DBInstanceIdentifier = var.rds_instance_id }
      statistic          = "Average"
      threshold          = 80
      period             = 300
      evaluation_periods = 3
      treat_missing_data = "notBreaching"
      alarm_description  = "RDS ${var.rds_instance_id} connection count is high"
      severity           = "warning"
    }

    rds_storage_low = {
      namespace           = "AWS/RDS"
      metric_name         = "FreeStorageSpace"
      dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
      statistic           = "Average"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 10737418240 # 10 GB in bytes
      period              = 3600
      evaluation_periods  = 1
      treat_missing_data  = "notBreaching"
      alarm_description   = "RDS ${var.rds_instance_id} has less than 10 GB of free storage"
      severity            = "critical"
    }

    # SQS alarms
    sqs_message_age = {
      namespace          = "AWS/SQS"
      metric_name        = "ApproximateAgeOfOldestMessage"
      dimensions         = { QueueName = var.sqs_queue_name }
      statistic          = "Maximum"
      threshold          = 300
      period             = 60
      evaluation_periods = 2
      treat_missing_data = "notBreaching"
      alarm_description  = "SQS queue ${var.sqs_queue_name} has messages older than 5 minutes"
      severity           = "warning"
    }

    sqs_depth_high = {
      namespace          = "AWS/SQS"
      metric_name        = "ApproximateNumberOfMessagesVisible"
      dimensions         = { QueueName = var.sqs_queue_name }
      statistic          = "Maximum"
      threshold          = 1000
      period             = 60
      evaluation_periods = 3
      treat_missing_data = "notBreaching"
      alarm_description  = "SQS queue ${var.sqs_queue_name} depth exceeds 1000 messages"
      severity           = "warning"
    }
  }

  # ── Anomaly Detection Alarms ──────────────────────────────────────────────────
  anomaly_detection_alarms = {
    lambda_duration_anomaly = {
      namespace          = "AWS/Lambda"
      metric_name        = "Duration"
      dimensions         = { FunctionName = var.lambda_function_name }
      statistic          = "Average"
      period             = 300
      evaluation_periods = 2
      band_width         = 2
      alarm_description  = "Lambda duration is behaving anomalously compared to its baseline"
    }
  }

  # ── Composite Alarms ──────────────────────────────────────────────────────────
  # Fires only when BOTH Lambda errors AND SQS message age are in ALARM together
  composite_alarms = {
    high_load = {
      alarm_rule        = "ALARM(\"${var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name}-lambda_errors\") AND ALARM(\"${var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name}-sqs_message_age\")"
      alarm_description = "Both Lambda errors and SQS backlog are high simultaneously — possible cascading failure"
      actions_enabled   = true
    }
  }

  # ── ASG Alarms ────────────────────────────────────────────────────────────────
  asg_alarms = {
    (var.asg_name) = {
      cpu_high_threshold          = 75
      cpu_high_evaluation_periods = 2
      cpu_high_period             = 300
      cpu_low_threshold           = 15
      cpu_low_evaluation_periods  = 3
      cpu_low_period              = 300
      min_group_size              = 2
      max_group_size              = 10
      alarm_on_failed_scaling     = true
    }
  }

  # ── AWS Backup Alarms ─────────────────────────────────────────────────────────
  backup_alarms = {
    enabled                      = var.enable_backup_alarms
    backup_job_failed_threshold  = 1
    restore_job_failed_threshold = 1
    copy_job_failed_threshold    = 1
    evaluation_periods           = 1
    period                       = 86400
  }

  # ── Log Metric Filters ────────────────────────────────────────────────────────
  log_metric_filters = {
    app_errors = {
      log_group_name     = "/aws/lambda/${var.lambda_function_name}"
      filter_pattern     = "[timestamp, requestId, level=\"ERROR\", message]"
      metric_name        = "AppErrors"
      metric_namespace   = "CustomMetrics/${var.project}"
      metric_value       = "1"
      unit               = "Count"
      create_alarm       = true
      alarm_threshold    = 1
      alarm_period       = 60
      evaluation_periods = 1
      alarm_description  = "Application errors detected in Lambda logs"
      treat_missing_data = "notBreaching"
    }

    payment_failures = {
      log_group_name     = "/aws/lambda/${var.lambda_function_name}"
      filter_pattern     = "{ $.event = \"payment_failed\" }"
      metric_name        = "PaymentFailures"
      metric_namespace   = "CustomMetrics/${var.project}"
      metric_value       = "1"
      unit               = "Count"
      create_alarm       = true
      alarm_threshold    = 3
      alarm_period       = 300
      evaluation_periods = 1
      alarm_description  = "Payment failures detected — investigate payment processor"
      treat_missing_data = "notBreaching"
    }
  }

  # ── Dashboard ─────────────────────────────────────────────────────────────────
  create_dashboard = var.create_dashboard
  dashboard_name   = var.dashboard_name

  dashboard_services = {
    lambda_functions = [var.lambda_function_name]
    rds_instances    = [var.rds_instance_id]
    sqs_queues       = [var.sqs_queue_name]
    asg_names        = [var.asg_name]
    ecs_clusters     = []
    ecs_services     = {}
    alb_names        = []
    ec2_instance_ids = []
  }

  # ── EventBridge Routing ───────────────────────────────────────────────────────
  enable_eventbridge_routing = var.enable_eventbridge_routing
  eventbridge_target_arn     = var.eventbridge_target_arn
}
