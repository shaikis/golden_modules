# Production tfvars — complete e-commerce example
# Replace placeholder ARNs with real values before applying.

aws_region  = "us-east-1"
name_prefix = "prod"

# SNS topic for CloudWatch alarm notifications
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-alerts"

# Backup vault in secondary region (us-west-2) for cross-region copies
backup_secondary_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:prod-dynamodb-vault-dr"

# KMS key for SSE on sensitive tables (users, orders, products, inventory)
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Kinesis Data Stream ARN for events table CDC → Firehose → S3 data lake
inventory_kinesis_stream_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/prod-ddb-events-cdc"

tags = {
  Environment = "production"
  Team        = "platform"
  CostCenter  = "ecommerce"
  Owner       = "platform-team@example.com"
  ManagedBy   = "terraform"
}
