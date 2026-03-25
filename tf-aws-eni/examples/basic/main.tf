provider "aws" { region = var.aws_region }

module "eni" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  network_interfaces = var.network_interfaces
}

output "eni_ids" { value = module.eni.eni_ids }
output "eni_private_ips" { value = module.eni.eni_private_ips }
output "eip_public_ips" { value = module.eni.eip_public_ips }
