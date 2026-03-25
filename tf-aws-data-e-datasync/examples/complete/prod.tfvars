aws_region          = "us-east-1"
raw_bucket_arn      = "arn:aws:s3:::my-raw-data-bucket"
archive_bucket_arn  = "arn:aws:s3:::my-archive-bucket"
efs_file_system_arn = "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-0abc123456789def0"
efs_subnet_arn      = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-0abc123456789def0"

efs_security_group_arns = [
  "arn:aws:ec2:us-east-1:123456789012:security-group/sg-0abc123456789def0",
]

nfs_agent_arns = [
  "arn:aws:datasync:us-east-1:123456789012:agent/agent-0abc123456789def0",
]

alarm_sns_topic_arn      = "arn:aws:sns:us-east-1:123456789012:datasync-alerts"
cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/datasync/tasks:*"
report_bucket_arn        = "arn:aws:s3:::my-datasync-reports-bucket"
