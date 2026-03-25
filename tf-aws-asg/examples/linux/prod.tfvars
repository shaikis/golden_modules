# ── Prod — dedicated VPC subnets, larger sizes ─────────────────────────────
aws_region  = "us-east-1"
name        = "app-linux"
environment = "prod"
project     = "platform"
owner       = "app-team"
cost_center = "CC-200"

instance_type   = "t3.large"
subnet_ids      = ["subnet-0prod1", "subnet-0prod2", "subnet-0prod3"]
security_group_ids      = ["sg-0appprod"]
iam_instance_profile_name = "ec2-ssm-instance-profile"

min_size         = 2
max_size         = 20
desired_capacity = 4

enable_cpu_scaling = true
cpu_target_value   = 65

scheduled_actions = {}   # no cost-saving schedule in prod

tags = { Team = "app-team"; Criticality = "high" }
