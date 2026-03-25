# ── Staging — matches production architecture at smaller scale ───────────────
aws_region  = "us-east-1"
name        = "app-linux"
environment = "staging"
project     = "platform"
owner       = "app-team"
cost_center = "CC-200"

instance_type             = "t3.large"
subnet_ids                = ["subnet-0stg1", "subnet-0stg2"]
security_group_ids        = ["sg-0appstg"]
iam_instance_profile_name = "ec2-ssm-instance-profile"

min_size         = 1
max_size         = 3
desired_capacity = 2

enable_cpu_scaling = true
cpu_target_value   = 70

scheduled_actions = {
  scale_down_night = {
    recurrence       = "0 20 * * MON-FRI"
    min_size         = 0
    max_size         = 3
    desired_capacity = 0
    time_zone        = "America/New_York"
  }
  scale_up_morning = {
    recurrence       = "0 7 * * MON-FRI"
    min_size         = 1
    max_size         = 3
    desired_capacity = 2
    time_zone        = "America/New_York"
  }
}

tags = { Team = "app-team"; CostSaving = "scheduled" }
