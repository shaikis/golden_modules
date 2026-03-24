# Production tfvars — global table example
# Replace placeholder ARNs with real values before applying.

primary_region = "us-east-1"
name_prefix    = "prod"

# SNS topic in us-east-1 for replication latency alarms
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-global-alerts"

tags = {
  Environment = "production"
  Team        = "platform"
  Global      = "true"
  ManagedBy   = "terraform"
  Owner       = "platform-team@example.com"
}
