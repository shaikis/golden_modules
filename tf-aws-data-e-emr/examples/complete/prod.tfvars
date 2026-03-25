aws_region = "us-east-1"

subnet_id = "subnet-0123456789abcdef0"
vpc_id    = "vpc-0123456789abcdef0"

studio_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0abcdef1234567890"
]

workspace_security_group_id = "sg-0123456789abcdef0"
engine_security_group_id    = "sg-0abcdef1234567890"

kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/mrk-12345678-1234-1234-1234-123456789012"
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:emr-alerts"

log_bucket       = "my-company-emr-logs-prod"
studio_s3_bucket = "my-company-emr-studio-prod"

serverless_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0abcdef1234567890"
]

serverless_security_group_ids = [
  "sg-0fedcba9876543210"
]
