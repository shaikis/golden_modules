# ── Prod — dedicated VPC, on-demand only, larger fleet ─────────────────────
aws_region  = "us-east-1"
name        = "app-windows"
environment = "prod"
project     = "platform"
owner       = "windows-team"
cost_center = "CC-300"

instance_type             = "m5.xlarge"
root_volume_size          = 150
subnet_ids                = ["subnet-0prod1", "subnet-0prod2", "subnet-0prod3"]
security_group_ids        = ["sg-0winprod"]
iam_instance_profile_name = "ec2-ssm-windows-profile"

# Domain join (dedicated prod AD)
windows_domain_name            = "corp.internal"
windows_domain_join_secret_arn = "arn:aws:secretsmanager:us-east-1:111122223333:secret/domain-join-prod"

min_size         = 2
max_size         = 20
desired_capacity = 4

use_mixed_instances_policy      = false # on-demand only for prod
on_demand_base_capacity         = 1
on_demand_percentage_above_base = 100

enable_cpu_scaling    = true
cpu_target_value      = 65
enable_memory_scaling = true
memory_target_value   = 75

scheduled_actions = {}

tags = {
  Team        = "windows-team"
  OS          = "windows"
  Criticality = "high"
}
