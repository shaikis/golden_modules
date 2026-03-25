provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = var.kms_name
  environment = var.environment
  project     = var.project
}

module "vpc" {
  source = "../../"

  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  availability_zones   = var.availability_zones

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  map_public_ip_on_launch = var.map_public_ip_on_launch
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway

  enable_vpn_gateway       = var.enable_vpn_gateway
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  interface_endpoints = var.interface_endpoints

  enable_flow_log           = var.enable_flow_log
  flow_log_destination_type = var.flow_log_destination_type
  flow_log_traffic_type     = var.flow_log_traffic_type
  flow_log_retention_days   = var.flow_log_retention_days
  flow_log_kms_key_id       = module.kms.key_arn

  tags = var.tags
}
