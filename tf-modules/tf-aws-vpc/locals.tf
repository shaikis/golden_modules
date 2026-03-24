locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  # How many AZs are actually requested
  az_count = length(var.availability_zones)

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-vpc"
  }

  tags = merge(local.default_tags, var.tags)

  # Subnet tag helpers
  public_subnet_tags   = merge(local.tags, var.public_subnet_tags, { Tier = "public" })
  private_subnet_tags  = merge(local.tags, var.private_subnet_tags, { Tier = "private" })
  database_subnet_tags = merge(local.tags, var.database_subnet_tags, { Tier = "database" })

  # Flow log delivery destinations
  flow_log_to_cloudwatch = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs"
  flow_log_to_s3         = var.enable_flow_log && var.flow_log_destination_type == "s3"

  # NAT gateway: single = one in first AZ; high_availability = one per AZ
  nat_gateway_count = (
    !var.enable_nat_gateway ? 0
    : var.single_nat_gateway ? 1
    : local.az_count
  )
}
