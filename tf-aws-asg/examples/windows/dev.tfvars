# ── Shared lower-env (dev / staging / qa use same VPC) ─────────────────────
aws_region  = "us-east-1"
name        = "app-windows"
environment = "dev"
project     = "platform"
owner       = "windows-team"
cost_center = "CC-300"

instance_type             = "t3.large"
root_volume_size          = 100
subnet_ids                = ["subnet-0dev1", "subnet-0dev2"] # shared lower-env subnets
security_group_ids        = ["sg-0win"]
iam_instance_profile_name = "ec2-ssm-windows-profile"

# Domain join (shared lower-env AD)
windows_domain_name            = "corp.internal"
windows_domain_join_secret_arn = "arn:aws:secretsmanager:us-east-1:111122223333:secret/domain-join-dev"

min_size         = 1
max_size         = 2
desired_capacity = 1

# Spot mix for dev cost savings
use_mixed_instances_policy      = true
on_demand_base_capacity         = 0
on_demand_percentage_above_base = 0
override_instance_types         = ["t3.large", "t3a.large", "m5.large"]

enable_cpu_scaling    = true
cpu_target_value      = 70
enable_memory_scaling = true
memory_target_value   = 75

scheduled_actions = {
  scale_down_night = {
    recurrence       = "0 20 * * MON-FRI"
    min_size         = 0
    max_size         = 2
    desired_capacity = 0
    time_zone        = "America/New_York"
  }
  scale_up_morning = {
    recurrence       = "0 7 * * MON-FRI"
    min_size         = 1
    max_size         = 2
    desired_capacity = 1
    time_zone        = "America/New_York"
  }
}

tags = {
  Team = "windows-team"
  OS   = "windows"
}
