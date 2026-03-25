aws_region  = "us-east-1"
name        = "app-golden"
environment = "prod"
project     = "platform"
owner       = "platform-team"
cost_center = "CC-100"

platform           = "Linux"
recipe_version     = "1.0.0"
root_volume_size   = 50
instance_types     = ["t3.large"]
subnet_id          = "subnet-0prod-private"
security_group_ids = ["sg-0imagebuilder-prod"]

pipeline_schedule_expression = "cron(0 2 * * ? *)"
pipeline_enabled             = true
distribution_regions         = ["us-west-2"]
