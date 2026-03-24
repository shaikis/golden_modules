provider "aws" { region = var.aws_region }

module "eks" {
  source      = "../../"
  name        = var.name
  subnet_ids  = var.subnet_ids
  vpc_id      = var.vpc_id
  environment = var.environment

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access
  public_access_cidrs     = var.public_access_cidrs

  node_groups = var.node_groups

  tags = var.tags
}

output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "oidc_arn" { value = module.eks.oidc_provider_arn }
