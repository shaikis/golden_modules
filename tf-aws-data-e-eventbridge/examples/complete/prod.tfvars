aws_region  = "us-east-1"
account_id  = "123456789012"
environment = "prod"

alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:ops-alerts"

tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Team        = "platform"
  CostCenter  = "engineering"
  Project     = "event-platform"
}
