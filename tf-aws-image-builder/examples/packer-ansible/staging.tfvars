# staging — dedicated subnets
aws_region  = "us-east-1"
name        = "app-golden"
environment = "staging"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

platform           = "Linux"
recipe_version     = "1.0.0"
root_volume_size   = 30
instance_types     = ["t3.medium"]
subnet_id          = "subnet-0stg-private"
security_group_ids = ["sg-0imagebuilder-stg"]

pipeline_schedule_expression = "cron(0 3 ? * SUN *)"
pipeline_enabled             = true
distribution_regions         = []
