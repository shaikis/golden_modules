provider "aws" { region = var.aws_region }

module "vpc_endpoints" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  vpc_id                     = var.vpc_id
  default_subnet_ids         = var.default_subnet_ids
  default_security_group_ids = var.default_security_group_ids
  default_route_table_ids    = var.default_route_table_ids

  endpoints = var.endpoints
}

output "gateway_endpoint_ids" { value = module.vpc_endpoints.gateway_endpoint_ids }
output "interface_endpoint_ids" { value = module.vpc_endpoints.interface_endpoint_ids }
