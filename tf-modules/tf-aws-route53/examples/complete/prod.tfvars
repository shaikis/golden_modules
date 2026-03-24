environment       = "prod"
name_prefix       = "prod"
public_zone_name  = "example.com"
private_zone_name = "internal.example.com"

# VPC — replace with actual VPC ID
vpc_id = "vpc-0prod123def456789a"

# ALB targets — replace with actual ALB DNS names and zone IDs
alb_dns_name           = "prod-alb-primary-1234567890.us-east-1.elb.amazonaws.com"
alb_zone_id            = "Z35SXDOTRQ7X7K"
secondary_alb_dns_name = "prod-alb-secondary-0987654321.eu-west-1.elb.amazonaws.com"
secondary_alb_zone_id  = "Z32O12XQLNTSW2"

# Resolver — multi-AZ setup for high availability
resolver_subnet_ids = [
  "subnet-0aaaabbbbcccc1111",
  "subnet-0aaaabbbbcccc2222",
]
resolver_security_group_ids = ["sg-0resolver123abc"]
on_premises_dns_ips         = ["192.168.1.53", "192.168.2.53"]

# DNSSEC — enabled in production
# Replace with actual KMS key ARN (must be in us-east-1, ECC_NIST_P256, SIGN_VERIFY)
enable_dnssec      = true
dnssec_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-00000000000000000000000000000001"

# CIDR routing — enabled in production for corporate network steering
enable_cidr_routing = true

# CloudWatch alarm — replace with actual production alarm name
rds_cloudwatch_alarm_name = "prod-rds-primary-health"

tags = {
  CostCenter = "engineering"
  Team       = "platform"
  Compliance = "pci-dss"
  DataClass  = "confidential"
}
