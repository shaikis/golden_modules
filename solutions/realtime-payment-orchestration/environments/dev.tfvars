name        = "acme-pay"
environment = "dev"
project     = "realtime-payments"
owner       = "payments-platform"
cost_center = "CC-PAYMENTS-DEV"

primary_region  = "us-east-1"
failover_region = "us-west-2"

vpc_cidr = "10.20.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = {
  "us-east-1a" = "10.20.1.0/24"
  "us-east-1b" = "10.20.2.0/24"
  "us-east-1c" = "10.20.3.0/24"
}
public_subnets = {
  "us-east-1a" = "10.20.101.0/24"
  "us-east-1b" = "10.20.102.0/24"
  "us-east-1c" = "10.20.103.0/24"
}

msk_instance_type   = "kafka.t3.small"
msk_broker_count    = 3
msk_ebs_volume_size = 100
msk_kafka_version   = "3.5.1"

lambda_code_s3_bucket      = "acme-pay-lambda-artifacts-dev"
lambda_memory_mb            = 512
lambda_timeout_seconds      = 60
lambda_reserved_concurrency = 50
lambda_architectures        = ["arm64"]

api_domain_name  = null
acm_certificate_arn = null
api_throttle_rate_limit  = 1000
api_throttle_burst_limit = 5000

waf_rate_limit_per_5min  = 1000
waf_geo_block_countries  = []
payment_api_allowed_cidrs = []

alarm_sns_email    = "dev-team@acme.com"
log_retention_days = 30
