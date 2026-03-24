# dev / staging / qa — same subnet, env changes
aws_region  = "us-east-1"
name        = "app-golden"
environment = "dev"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

platform           = "Linux"
recipe_version     = "1.0.0"
root_volume_size   = 30
instance_types     = ["t3.medium"]
subnet_id          = "subnet-0dev-private" # shared lower-env subnet
security_group_ids = ["sg-0imagebuilder"]

pipeline_schedule_expression = "cron(0 2 ? * SUN *)"
pipeline_enabled             = true
distribution_regions         = []
