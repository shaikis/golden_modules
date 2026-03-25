provider "aws" { region = var.aws_region }

module "kms" { source = "../../../tf-aws-kms"; name = "aurora-${var.environment}"; environment = var.environment }

module "aurora" {
  source = "../../"
  name   = var.name

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  kms_key_id             = module.kms.key_arn

  environment         = var.environment
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  cluster_instances = var.cluster_instances

  tags = var.tags
}

output "cluster_endpoint" { value = module.aurora.cluster_endpoint }
output "secret_arn"       { value = module.aurora.cluster_master_user_secret_arn }
