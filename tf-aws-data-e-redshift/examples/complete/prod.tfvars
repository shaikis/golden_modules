aws_region = "us-east-1"

# Replace with actual KMS key ARN from tf-aws-kms module
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Replace with actual SNS topic ARN for alarm notifications
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:redshift-alarms"

# Production VPC subnets (private subnets across 3 AZs)
prod_subnet_ids = [
  "subnet-0a1b2c3d4e5f6a7b8",
  "subnet-1b2c3d4e5f6a7b8c9",
  "subnet-2c3d4e5f6a7b8c9d0",
]

# Dev VPC subnets (private subnets across 2 AZs)
dev_subnet_ids = [
  "subnet-dev000000000000a",
  "subnet-dev000000000000b",
]

# Security groups
prod_security_group_ids = ["sg-0prod00000000000a"]
dev_security_group_ids  = ["sg-0dev000000000000a"]

# Analytics consumer account for data sharing
analytics_consumer_account_id = "987654321098"

tags = {
  Environment = "production"
  Project     = "data-warehouse"
  ManagedBy   = "Terraform"
  Owner       = "data-platform-team"
  CostCenter  = "engineering"
}
