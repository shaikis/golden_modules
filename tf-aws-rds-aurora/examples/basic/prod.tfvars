aws_region             = "us-east-1"
name                   = "prod-aurora"
environment            = "prod"
engine                 = "aurora-postgresql"
engine_version         = "15.4"
instance_class         = "db.r6g.large"
db_subnet_group_name   = "prod-db-subnet-group"
vpc_security_group_ids = ["sg-0123456789abcdef0"]
deletion_protection    = true
skip_final_snapshot    = false
cluster_instances = {
  "1" = { promotion_tier = 0 }
  "2" = { promotion_tier = 1 }
  "3" = { promotion_tier = 1 }
}
tags = {
  Environment = "prod"
}
