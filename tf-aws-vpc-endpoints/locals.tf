locals {
  name   = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  region = data.aws_region.current.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-vpc-endpoints"
    },
    var.tags
  )

  # Separate gateway vs interface endpoints from the combined map
  gateway_endpoints   = { for k, v in var.endpoints : k => v if v.vpc_endpoint_type == "Gateway" }
  interface_endpoints = { for k, v in var.endpoints : k => v if v.vpc_endpoint_type == "Interface" }
}
