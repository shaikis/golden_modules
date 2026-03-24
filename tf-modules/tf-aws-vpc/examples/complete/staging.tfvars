aws_region               = "us-east-1"
name                     = "platform"
name_prefix              = "staging"
environment              = "staging"
project                  = "platform"
owner                    = "infra-team"
cost_center              = "CC-100"
kms_name                 = "vpc-flowlogs"
cidr_block               = "10.11.0.0/16"
enable_dns_hostnames     = true
enable_dns_support       = true
availability_zones       = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs      = ["10.11.0.0/24", "10.11.1.0/24"]
private_subnet_cidrs     = ["10.11.10.0/24", "10.11.11.0/24"]
database_subnet_cidrs    = ["10.11.20.0/24", "10.11.21.0/24"]
map_public_ip_on_launch  = false
enable_nat_gateway       = true
single_nat_gateway       = true
enable_vpn_gateway       = false
enable_s3_endpoint       = true
enable_dynamodb_endpoint = true
interface_endpoints = {
  ssm = {
    service_name        = "com.amazonaws.us-east-1.ssm"
    private_dns_enabled = true
  }
  ssmmessages = {
    service_name        = "com.amazonaws.us-east-1.ssmmessages"
    private_dns_enabled = true
  }
  ec2messages = {
    service_name        = "com.amazonaws.us-east-1.ec2messages"
    private_dns_enabled = true
  }
}
enable_flow_log           = true
flow_log_destination_type = "cloud-watch-logs"
flow_log_traffic_type     = "ALL"
flow_log_retention_days   = 180
tags = {
  Environment        = "staging"
  DataClassification = "Internal"
  Compliance         = "SOC2"
}
