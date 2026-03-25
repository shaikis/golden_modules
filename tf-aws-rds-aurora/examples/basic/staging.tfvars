aws_region             = "us-east-1"
name                   = "staging-aurora"
environment            = "staging"
engine                 = "aurora-postgresql"
engine_version         = "15.4"
instance_class         = "db.t3.large"
db_subnet_group_name   = "staging-db-subnet-group"
vpc_security_group_ids = []
deletion_protection    = false
skip_final_snapshot    = true
cluster_instances = {
  "1" = {}
  "2" = {}
}
tags = {
  Environment = "staging"
}
