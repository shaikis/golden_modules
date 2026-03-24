aws_region           = "us-east-1"
name                 = "my-app-db"
environment          = "staging"
engine               = "postgres"
instance_class       = "db.t3.large"
db_name              = "appdb"
db_subnet_group_name = "staging-db-subnet-group"
multi_az             = false
skip_final_snapshot  = true
deletion_protection  = false
tags = {
  Environment = "staging"
}
