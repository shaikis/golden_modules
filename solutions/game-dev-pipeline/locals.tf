locals {
  prefix = "${var.name}-${var.environment}"

  tags = merge(var.tags, {
    Name        = local.prefix
    Environment = var.environment
    Solution    = "game-dev-pipeline"
    ManagedBy   = "terraform"
  })

  kms_key_arn = var.enable_kms ? module.kms[0].key_arns["gamedev"] : null

  # Subnet CIDR calculations derived from the VPC CIDR block.
  # Public subnets: /20 slices starting at index 0.
  # Private subnets: /20 slices starting at index = number of AZs.
  public_subnet_cidrs  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i + length(var.availability_zones))]
}
