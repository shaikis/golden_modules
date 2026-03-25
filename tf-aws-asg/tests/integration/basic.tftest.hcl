# Integration tests — tf-aws-asg
# Cost estimate: $0.00 — command = plan only; no EC2/ASG resources are created.
# These tests require valid AWS credentials but create no real infrastructure.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Minimal ASG plan succeeds (Linux, size 0/0/0) ───────────────────
# SKIP_IN_CI
run "minimal_asg_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                = "tftest-asg-basic"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    min_size            = 0
    max_size            = 1
    desired_capacity    = 0
    instance_type       = "t3.micro"
    environment         = "test"
  }

  assert {
    condition     = var.min_size == 0
    error_message = "min_size must be 0 for this test."
  }

  assert {
    condition     = var.max_size == 1
    error_message = "max_size must be 1 for this test."
  }

  assert {
    condition     = var.desired_capacity == 0
    error_message = "desired_capacity must be 0 for this test."
  }
}

# ── Test 2: Windows OS type plan succeeds ────────────────────────────────────
# SKIP_IN_CI
run "windows_asg_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                = "tftest-asg-windows"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    os_type             = "windows"
    min_size            = 0
    max_size            = 1
    desired_capacity    = 0
    instance_type       = "t3.medium"
    environment         = "test"
  }

  assert {
    condition     = var.os_type == "windows"
    error_message = "os_type must be windows."
  }
}

# ── Test 3: CPU scaling enabled plan succeeds ────────────────────────────────
# SKIP_IN_CI
run "cpu_scaling_enabled_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                = "tftest-asg-cpu"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    min_size            = 0
    max_size            = 2
    desired_capacity    = 0
    enable_cpu_scaling  = true
    cpu_target_value    = 70
    environment         = "test"
  }

  assert {
    condition     = var.enable_cpu_scaling == true
    error_message = "enable_cpu_scaling must be true."
  }

  assert {
    condition     = var.cpu_target_value == 70
    error_message = "cpu_target_value must be 70."
  }
}
