aws_region             = "us-east-1"
name                   = "dev-aurora"
environment            = "dev"
engine                 = "aurora-postgresql"
engine_version         = "15.4"
instance_class         = "db.t3.medium"
db_subnet_group_name   = "dev-db-subnet-group"
vpc_security_group_ids = []
deletion_protection    = false
skip_final_snapshot    = true
cluster_instances = {
  "1" = {}
}
tags = {
  Environment = "dev"
}
