# ---------------------------------------------------------------------------
# Production variable values for tf-aws-kinesis complete example
# ---------------------------------------------------------------------------
# Replace ALL placeholder values with real ARNs/URLs before applying.
# Store sensitive values (redshift_password) in AWS Secrets Manager or
# CI/CD secret stores — never commit them to version control.
# ---------------------------------------------------------------------------

aws_region  = "us-east-1"
environment = "prod"
project     = "data-platform"
name_prefix = "prod-"

# SNS topic for alarm notifications (must be pre-created)
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-data-platform-alerts"

# ---------------------------------------------------------------------------
# S3 Buckets (must be pre-created with appropriate bucket policies)
# ---------------------------------------------------------------------------

data_lake_bucket_arn       = "arn:aws:s3:::prod-data-lake-123456789012"
redshift_backup_bucket_arn = "arn:aws:s3:::prod-redshift-backup-123456789012"

# ---------------------------------------------------------------------------
# Redshift
# ---------------------------------------------------------------------------

redshift_jdbc_url = "jdbc:redshift://prod-cluster.abc123xyz.us-east-1.redshift.amazonaws.com:5439/datawarehouse"
redshift_username = "firehose_loader"
# redshift_password — set via environment variable:
#   export TF_VAR_redshift_password="<secure-password>"
# Or use: -var="redshift_password=<value>" on the CLI

# ---------------------------------------------------------------------------
# Flink / Kinesis Data Analytics
# ---------------------------------------------------------------------------

flink_code_s3_bucket     = "prod-flink-artifacts-123456789012"
flink_code_s3_key        = "flink-apps/clickstream-processor-1.2.0.jar"
analytics_log_stream_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/kinesis-analytics/prod-clickstream-processor:log-stream:kinesis-analytics-log-stream"

# ---------------------------------------------------------------------------
# Lambda Transformation
# ---------------------------------------------------------------------------

lambda_processor_arn = "arn:aws:lambda:us-east-1:123456789012:function:prod-firehose-transform"

# ---------------------------------------------------------------------------
# KMS Encryption
# ---------------------------------------------------------------------------

kms_key_id     = "alias/prod/kinesis"
s3_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-aaaabbbbccccdddd11112222333344445555"
