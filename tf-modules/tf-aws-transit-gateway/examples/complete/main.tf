provider "aws" { region = var.aws_region }

module "tgw" {
  source      = "../../"
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  amazon_side_asn                 = var.amazon_side_asn
  vpn_ecmp_support                = var.vpn_ecmp_support
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation

  vpc_attachments  = var.vpc_attachments
  tgw_route_tables = var.tgw_route_tables
  tgw_routes       = var.tgw_routes

  ram_share_enabled             = var.ram_share_enabled
  ram_allow_external_principals = var.ram_allow_external_principals
  ram_principals                = var.ram_principals
}
