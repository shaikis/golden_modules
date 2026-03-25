aws_region           = "us-east-1"
name                 = "my-app-db"
environment          = "dev"
engine               = "postgres"
instance_class       = "db.t3.medium"
db_name              = "appdb"
db_subnet_group_name = "dev-db-subnet-group"
multi_az             = false
skip_final_snapshot  = true
deletion_protection  = false
tags = {
  Environment = "dev"
}
