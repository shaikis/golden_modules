# ---------------------------------------------------------------------------
# Outputs — Kinesis Data Streams
# ---------------------------------------------------------------------------

output "stream_arns" {
  description = "Map of stream key to ARN."
  value       = { for k, v in aws_kinesis_stream.this : k => v.arn }
}

output "stream_names" {
  description = "Map of stream key to stream name."
  value       = { for k, v in aws_kinesis_stream.this : k => v.name }
}

output "stream_ids" {
  description = "Map of stream key to stream resource ID."
  value       = { for k, v in aws_kinesis_stream.this : k => v.id }
}

output "stream_shard_counts" {
  description = "Map of stream key to shard count (null for ON_DEMAND streams)."
  value       = { for k, v in aws_kinesis_stream.this : k => v.shard_count }
}

# ---------------------------------------------------------------------------
# Outputs — Enhanced Fan-Out Consumers
# ---------------------------------------------------------------------------

output "consumer_arns" {
  description = "Map of consumer key to enhanced fan-out consumer ARN. Empty map when create_stream_consumers = false."
  value       = try({ for k, v in aws_kinesis_stream_consumer.this : k => v.arn }, {})
}

output "consumer_names" {
  description = "Map of consumer key to consumer name. Empty map when create_stream_consumers = false."
  value       = try({ for k, v in aws_kinesis_stream_consumer.this : k => v.name }, {})
}

# ---------------------------------------------------------------------------
# Outputs — Firehose Delivery Streams
# ---------------------------------------------------------------------------

output "firehose_arns" {
  description = "Map of firehose key to delivery stream ARN. Empty map when create_firehose_streams = false."
  value = try(merge(
    { for k, v in aws_kinesis_firehose_delivery_stream.s3 : k => v.arn },
    { for k, v in aws_kinesis_firehose_delivery_stream.redshift : k => v.arn },
    { for k, v in aws_kinesis_firehose_delivery_stream.opensearch : k => v.arn },
    { for k, v in aws_kinesis_firehose_delivery_stream.splunk : k => v.arn },
    { for k, v in aws_kinesis_firehose_delivery_stream.http_endpoint : k => v.arn },
  ), {})
}

output "firehose_names" {
  description = "Map of firehose key to delivery stream name. Empty map when create_firehose_streams = false."
  value = try(merge(
    { for k, v in aws_kinesis_firehose_delivery_stream.s3 : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.redshift : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.opensearch : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.splunk : k => v.name },
    { for k, v in aws_kinesis_firehose_delivery_stream.http_endpoint : k => v.name },
  ), {})
}

# ---------------------------------------------------------------------------
# Outputs — Kinesis Data Analytics v2
# ---------------------------------------------------------------------------

output "analytics_application_arns" {
  description = "Map of analytics application key to application ARN. Empty map when create_analytics_applications = false."
  value = try(merge(
    { for k, v in aws_kinesisanalyticsv2_application.auto_role : k => v.arn },
    { for k, v in aws_kinesisanalyticsv2_application.existing_role : k => v.arn },
  ), {})
}

output "analytics_application_names" {
  description = "Map of analytics application key to application name. Empty map when create_analytics_applications = false."
  value = try(merge(
    { for k, v in aws_kinesisanalyticsv2_application.auto_role : k => v.name },
    { for k, v in aws_kinesisanalyticsv2_application.existing_role : k => v.name },
  ), {})
}

output "analytics_application_versions" {
  description = "Map of analytics application key to application version. Empty map when create_analytics_applications = false."
  value = try(merge(
    { for k, v in aws_kinesisanalyticsv2_application.auto_role : k => v.version_id },
    { for k, v in aws_kinesisanalyticsv2_application.existing_role : k => v.version_id },
  ), {})
}

# ---------------------------------------------------------------------------
# Outputs — IAM Roles
# ---------------------------------------------------------------------------

output "producer_role_arn" {
  description = "ARN of the Kinesis producer IAM role. Null when create_iam_roles = false or create_producer_role = false."
  value       = try(aws_iam_role.producer[0].arn, null)
}

output "producer_role_name" {
  description = "Name of the Kinesis producer IAM role. Null when create_iam_roles = false or create_producer_role = false."
  value       = try(aws_iam_role.producer[0].name, null)
}

output "consumer_role_arn" {
  description = "ARN of the Kinesis consumer IAM role. Null when create_iam_roles = false or create_consumer_role = false."
  value       = try(aws_iam_role.consumer[0].arn, null)
}

output "consumer_role_name" {
  description = "Name of the Kinesis consumer IAM role. Null when create_iam_roles = false or create_consumer_role = false."
  value       = try(aws_iam_role.consumer[0].name, null)
}

output "firehose_role_arn" {
  description = "ARN of the Firehose delivery IAM role. Null when create_iam_roles = false or create_firehose_role = false."
  value       = try(aws_iam_role.firehose[0].arn, null)
}

output "firehose_role_name" {
  description = "Name of the Firehose delivery IAM role. Null when create_iam_roles = false or create_firehose_role = false."
  value       = try(aws_iam_role.firehose[0].name, null)
}

output "analytics_role_arns" {
  description = "Map of analytics application key to auto-created execution role ARN. Empty map when create_analytics_applications = false."
  value       = try({ for k, v in aws_iam_role.analytics : k => v.arn }, {})
}

output "lambda_transform_role_arn" {
  description = "ARN of the Lambda transformation IAM role. Null when create_iam_roles = false or create_lambda_transform_role = false."
  value       = try(aws_iam_role.lambda_transform[0].arn, null)
}

# ---------------------------------------------------------------------------
# Outputs — CloudWatch Alarms
# ---------------------------------------------------------------------------

output "alarm_ids" {
  description = "Map of all CloudWatch alarm IDs keyed by alarm name. Empty map when create_alarms = false."
  value = try(merge(
    { for k, v in aws_cloudwatch_metric_alarm.iterator_age : k => v.id },
    { for k, v in aws_cloudwatch_metric_alarm.write_throttle : k => v.id },
    { for k, v in aws_cloudwatch_metric_alarm.read_throttle : k => v.id },
    { for k, v in aws_cloudwatch_metric_alarm.put_records_failed : k => v.id },
    { for k, v in aws_cloudwatch_metric_alarm.firehose_freshness : k => v.id },
    { for k, v in aws_cloudwatch_metric_alarm.firehose_delivery_success : k => v.id },
    { for k, v in aws_cloudwatch_metric_alarm.firehose_throttled : k => v.id },
  ), {})
}

output "alarm_arns" {
  description = "Map of all CloudWatch alarm ARNs keyed by alarm name. Empty map when create_alarms = false."
  value = try(merge(
    { for k, v in aws_cloudwatch_metric_alarm.iterator_age : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.write_throttle : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.read_throttle : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.put_records_failed : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.firehose_freshness : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.firehose_delivery_success : k => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.firehose_throttled : k => v.arn },
  ), {})
}

# ---------------------------------------------------------------------------
# Outputs — Region / Account context
# ---------------------------------------------------------------------------

output "aws_region" {
  description = "AWS region where the module is deployed."
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID where the module is deployed."
  value       = data.aws_caller_identity.current.account_id
}
