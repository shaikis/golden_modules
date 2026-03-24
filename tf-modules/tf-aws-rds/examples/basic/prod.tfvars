aws_region           = "us-east-1"
name                 = "my-app-db"
environment          = "prod"
engine               = "postgres"
instance_class       = "db.r6g.large"
db_name              = "appdb"
db_subnet_group_name = "prod-db-subnet-group"
multi_az             = true
skip_final_snapshot  = false
deletion_protection  = true
tags = {
  Environment = "prod"
}
