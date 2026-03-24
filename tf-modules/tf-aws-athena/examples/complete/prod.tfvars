aws_region  = "us-east-1"
name_prefix = "prod"

# ---------------------------------------------------------------------------
# S3 — replace with actual bucket names and ARNs in your account
# ---------------------------------------------------------------------------
results_bucket_name   = "prod-athena-query-results-123456789012"
results_bucket_arn    = "arn:aws:s3:::prod-athena-query-results-123456789012"
data_lake_bucket_name = "prod-data-lake-raw-123456789012"
data_lake_bucket_arn  = "arn:aws:s3:::prod-data-lake-raw-123456789012"

# ---------------------------------------------------------------------------
# KMS — replace with your actual KMS key ARN
# ---------------------------------------------------------------------------
results_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

# ---------------------------------------------------------------------------
# Lambda federated connector — replace with actual function ARN
# ---------------------------------------------------------------------------
lambda_connector_arn = "arn:aws:lambda:us-east-1:123456789012:function:prod-athena-federated-connector"

# ---------------------------------------------------------------------------
# Account ID — used for expected_bucket_owner
# ---------------------------------------------------------------------------
account_id = "123456789012"

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------
tags = {
  Environment = "production"
  Team        = "data-platform"
  CostCenter  = "data-engineering"
  ManagedBy   = "terraform"
  Project     = "data-lakehouse"
}
