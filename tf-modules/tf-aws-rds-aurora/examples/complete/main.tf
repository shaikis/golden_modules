provider "aws" { alias = "primary"; region = var.aws_region_primary }
provider "aws" { alias = "dr";      region = var.aws_region_dr }

module "kms_primary" { source = "../../../tf-aws-kms"; name = "aurora-primary"; environment = var.environment; providers = { aws = aws.primary } }
module "kms_dr"      { source = "../../../tf-aws-kms"; name = "aurora-dr";      environment = var.environment; providers = { aws = aws.dr } }

# ---- Primary Aurora Cluster (writes) ----
module "aurora_primary" {
  source    = "../../"
  providers = { aws = aws.primary }

  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  cost_center = var.cost_center

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  kms_key_id             = module.kms_primary.key_arn

  manage_master_user_password   = var.manage_master_user_password
  master_user_secret_kms_key_id = module.kms_primary.key_arn

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  create_global_cluster         = true
  global_cluster_engine         = var.engine
  global_cluster_engine_version = var.engine_version

  cluster_instances = var.primary_cluster_instances

  autoscaling_enabled      = var.autoscaling_enabled
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_target_cpu   = var.autoscaling_target_cpu

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = module.kms_primary.key_arn
  performance_insights_retention_period = var.performance_insights_retention_period

  create_cluster_parameter_group = var.create_cluster_parameter_group
  cluster_parameter_group_family = var.cluster_parameter_group_family
  cluster_parameters             = var.cluster_parameters

  tags = var.tags
}

# ---- DR Aurora Cluster (secondary, read-only until failover) ----
module "aurora_dr" {
  source    = "../../"
  providers = { aws = aws.dr }

  name        = "${var.name}-dr"
  name_prefix = var.name_prefix
  environment = var.environment

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  global_cluster_identifier = module.aurora_primary.global_cluster_id
  source_region             = var.aws_region_primary

  db_subnet_group_name   = var.dr_db_subnet_group_name
  vpc_security_group_ids = var.dr_vpc_security_group_ids
  kms_key_id             = module.kms_dr.key_arn

  storage_encrypted       = true
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = 7

  cluster_instances = var.dr_cluster_instances

  tags = var.tags
}

# ---- Serverless v2 cluster example (separate) ----
module "aurora_serverless" {
  source    = "../../"
  providers = { aws = aws.primary }

  name        = "${var.name}-serverless"
  environment = var.environment

  engine         = var.engine
  engine_version = var.engine_version

  serverlessv2_scaling = [{ min_capacity = 0.5; max_capacity = 32 }]
  cluster_instances    = { "1" = { instance_class = "db.serverless" } }

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  kms_key_id             = module.kms_primary.key_arn
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = var.skip_final_snapshot

  tags = var.tags
}

output "primary_endpoint"   { value = module.aurora_primary.cluster_endpoint }
output "primary_reader_ep"  { value = module.aurora_primary.cluster_reader_endpoint }
output "dr_endpoint"        { value = module.aurora_dr.cluster_endpoint }
output "serverless_ep"      { value = module.aurora_serverless.cluster_endpoint }
output "secret_arn"         { value = module.aurora_primary.cluster_master_user_secret_arn }
