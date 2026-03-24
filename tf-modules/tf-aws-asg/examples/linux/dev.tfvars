# ── Shared lower-env (dev / staging / qa use same VPC subnets) ─────────────
aws_region  = "us-east-1"
name        = "app-linux"
environment = "dev"
project     = "platform"
owner       = "app-team"
cost_center = "CC-200"

instance_type   = "t3.medium"
subnet_ids      = ["subnet-0dev1", "subnet-0dev2"]   # shared lower-env subnets
security_group_ids      = ["sg-0app"]
iam_instance_profile_name = "ec2-ssm-instance-profile"

min_size         = 1
max_size         = 2
desired_capacity = 1

enable_cpu_scaling = true
cpu_target_value   = 70

# Scale down at night, up in morning (business hours)
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

tags = { Team = "app-team"; CostSaving = "scheduled" }
