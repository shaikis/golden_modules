# Production environment configuration
name        = "acme-pay"
environment = "prod"
project     = "realtime-payments"
owner       = "payments-platform"
cost_center = "CC-PAYMENTS-PROD"

primary_region  = "us-east-1"
failover_region = "us-west-2"

# Network
vpc_cidr = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = {
  "us-east-1a" = "10.10.1.0/24"
  "us-east-1b" = "10.10.2.0/24"
  "us-east-1c" = "10.10.3.0/24"
}
public_subnets = {
  "us-east-1a" = "10.10.101.0/24"
  "us-east-1b" = "10.10.102.0/24"
  "us-east-1c" = "10.10.103.0/24"
}

# MSK — production-grade brokers with Graviton (cost savings + performance)
msk_instance_type   = "kafka.m5.4xlarge"
msk_broker_count    = 3
msk_ebs_volume_size = 2000
msk_kafka_version   = "3.5.1"

# Lambda
lambda_code_s3_bucket       = "acme-pay-lambda-artifacts-prod"
lambda_memory_mb             = 1024
lambda_timeout_seconds       = 60
lambda_reserved_concurrency  = 500
lambda_architectures         = ["arm64"]  # Graviton — 20% cheaper + faster

# API
api_domain_name         = "api.payments.acme.com"
acm_certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/REPLACE_WITH_REAL_CERT"
api_throttle_rate_limit  = 10000
api_throttle_burst_limit = 50000

# WAF
waf_rate_limit_per_5min  = 10000
waf_geo_block_countries  = ["KP", "IR", "SY", "CU"]  # OFAC sanctioned
payment_api_allowed_cidrs = [
  "203.0.113.0/24",   # Partner bank A
  "198.51.100.0/24",  # Partner bank B
]

# Observability
alarm_sns_email    = "payments-oncall@acme.com"
log_retention_days = 365
