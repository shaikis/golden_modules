provider "aws" { region = var.aws_region }

module "rds" {
  source               = "../../"
  name                 = var.name
  engine               = var.engine
  instance_class       = var.instance_class
  db_name              = var.db_name
  db_subnet_group_name = var.db_subnet_group_name
  environment          = var.environment
  multi_az             = var.multi_az
  skip_final_snapshot  = var.skip_final_snapshot
  deletion_protection  = var.deletion_protection
  tags                 = var.tags
}

output "endpoint" { value = module.rds.db_instance_endpoint }
