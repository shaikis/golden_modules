# ---------------------------------------------------------------------------
# Production variable values for the complete example
# ---------------------------------------------------------------------------

aws_region  = "us-east-1"
environment = "prod"
project     = "data-platform"

# S3 buckets
data_lake_bucket_name = "acme-data-platform-prod-datalake-us-east-1"
assets_bucket_name    = "acme-data-platform-prod-assets-us-east-1"

# RDS PostgreSQL source
rds_jdbc_url          = "jdbc:postgresql://orders-db.prod.us-east-1.rds.amazonaws.com:5432/orders"
rds_username          = "glue_reader"
rds_password          = "REPLACE_WITH_SECRETS_MANAGER_REF"
rds_subnet_id         = "subnet-0abc123456789def0"
rds_security_group_id = "sg-0abc123456789def0"
rds_availability_zone = "us-east-1a"

# Amazon MSK (Kafka)
msk_bootstrap_servers = "b-1.acme-msk.prod.kafka.us-east-1.amazonaws.com:9092,b-2.acme-msk.prod.kafka.us-east-1.amazonaws.com:9092"
msk_subnet_id         = "subnet-0def123456789abc1"
msk_security_group_id = "sg-0def123456789abc1"

# KMS key for Glue encryption
glue_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Additional resource tags
tags = {
  CostCentre = "data-engineering"
  Owner      = "data-platform-team@acme.com"
  Compliance = "SOC2"
  DataClass  = "confidential"
}
