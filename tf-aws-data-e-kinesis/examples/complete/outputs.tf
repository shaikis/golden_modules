output "stream_arns" {
  description = "Map of stream key to ARN."
  value       = module.kinesis.stream_arns
}

output "stream_names" {
  description = "Map of stream key to stream name."
  value       = module.kinesis.stream_names
}

output "consumer_arns" {
  description = "Map of enhanced fan-out consumer key to ARN."
  value       = module.kinesis.consumer_arns
}

output "firehose_arns" {
  description = "Map of firehose key to delivery stream ARN."
  value       = module.kinesis.firehose_arns
}

output "firehose_names" {
  description = "Map of firehose key to delivery stream name."
  value       = module.kinesis.firehose_names
}

output "analytics_application_arns" {
  description = "Map of analytics application key to ARN."
  value       = module.kinesis.analytics_application_arns
}

output "producer_role_arn" {
  description = "ARN of the Kinesis producer IAM role."
  value       = module.kinesis.producer_role_arn
}

output "consumer_role_arn" {
  description = "ARN of the Kinesis consumer IAM role."
  value       = module.kinesis.consumer_role_arn
}

output "firehose_role_arn" {
  description = "ARN of the Firehose delivery IAM role."
  value       = module.kinesis.firehose_role_arn
}

output "alarm_ids" {
  description = "Map of all CloudWatch alarm IDs."
  value       = module.kinesis.alarm_ids
}

output "aws_region" {
  description = "AWS region of the deployment."
  value       = module.kinesis.aws_region
}
