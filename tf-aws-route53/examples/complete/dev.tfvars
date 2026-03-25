environment       = "dev"
name_prefix       = "dev"
public_zone_name  = "dev.example.com"
private_zone_name = "internal.dev.example.com"

# VPC — replace with actual VPC ID
vpc_id = "vpc-0abc123def456789a"

# ALB targets — replace with actual ALB DNS names and zone IDs
alb_dns_name           = "dev-alb-primary-1234567890.us-east-1.elb.amazonaws.com"
alb_zone_id            = "Z35SXDOTRQ7X7K"
secondary_alb_dns_name = "dev-alb-secondary-0987654321.us-east-1.elb.amazonaws.com"
secondary_alb_zone_id  = "Z35SXDOTRQ7X7K"

# Resolver — leave empty to skip resolver endpoint creation in dev
resolver_subnet_ids         = []
resolver_security_group_ids = []
on_premises_dns_ips         = []

# DNSSEC — disabled in dev (saves cost; enable in prod)
enable_dnssec      = false
dnssec_kms_key_arn = null

# CIDR routing — disabled in dev
enable_cidr_routing = false

# CloudWatch alarm — replace with actual alarm name
rds_cloudwatch_alarm_name = "dev-rds-primary-health"

tags = {
  CostCenter = "engineering"
  Team       = "platform"
}
