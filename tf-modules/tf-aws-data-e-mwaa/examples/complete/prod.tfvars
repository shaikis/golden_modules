aws_region  = "us-east-1"
name_prefix = "prod-"

kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234567890abcdef0"
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-mwaa-alerts"

prod_source_bucket_arn = "arn:aws:s3:::prod-mwaa-dags-123456789012"
dev_source_bucket_arn  = "arn:aws:s3:::dev-mwaa-dags-123456789012"

prod_subnet_ids = [
  "subnet-0abc123def456789a",
  "subnet-0abc123def456789b",
]

dev_subnet_ids = [
  "subnet-0abc123def456789c",
  "subnet-0abc123def456789d",
]

prod_security_group_ids = ["sg-0prod1234567890abc"]
dev_security_group_ids  = ["sg-0dev1234567890abc"]

tags = {
  Environment = "prod"
  Team        = "data-engineering"
  CostCenter  = "DE-001"
  ManagedBy   = "terraform"
  Module      = "tf-aws-data-e-mwaa"
}
