aws_region_primary                    = "us-east-1"
aws_region_dr                         = "us-west-2"
name                                  = "platform"
name_prefix                           = "prod"
environment                           = "prod"
project                               = "platform"
cost_center                           = "CC-400"
engine                                = "aurora-postgresql"
engine_version                        = "15.4"
instance_class                        = "db.r6g.large"
db_subnet_group_name                  = "prod-db-subnet-group"
dr_db_subnet_group_name               = "prod-dr-db-subnet-group"
vpc_security_group_ids                = ["sg-primary"]
dr_vpc_security_group_ids             = ["sg-dr"]
backup_retention_period               = 30
deletion_protection                   = true
skip_final_snapshot                   = false
autoscaling_enabled                   = true
autoscaling_min_capacity              = 1
autoscaling_max_capacity              = 8
autoscaling_target_cpu                = 70
performance_insights_enabled          = true
performance_insights_retention_period = 7
create_cluster_parameter_group        = true
cluster_parameter_group_family        = "aurora-postgresql15"
primary_cluster_instances = {
  "1" = { promotion_tier = 0 }
  "2" = { promotion_tier = 1 }
  "3" = { promotion_tier = 1 }
}
dr_cluster_instances = {
  "1" = { promotion_tier = 0 }
  "2" = { promotion_tier = 1 }
}
tags = {
  Environment = "prod"
}
