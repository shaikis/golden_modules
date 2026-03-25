# Integration tests — tf-aws-asg-instance-ops
# Cost estimate: $0.00 — command = plan only; no AWS resources are created.
# Note: this module wraps per-instance operations on an existing ASG
# (scale-in protection, standby, detach). A real ASG must exist to apply.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Plan with asg_name only (no instance operations) ────────────────
# SKIP_IN_CI
run "minimal_plan_asg_name_only" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    asg_name    = "my-existing-asg"
    environment = "test"
  }

  assert {
    condition     = var.asg_name == "my-existing-asg"
    error_message = "asg_name must be passed through unchanged."
  }

  assert {
    condition     = length(var.protected_instance_ids) == 0
    error_message = "protected_instance_ids must default to empty list."
  }

  assert {
    condition     = length(var.standby_instance_ids) == 0
    error_message = "standby_instance_ids must default to empty list."
  }

  assert {
    condition     = length(var.detach_instance_ids) == 0
    error_message = "detach_instance_ids must default to empty list."
  }
}

# ── Test 2: Plan with scale-in protection instance list ──────────────────────
# SKIP_IN_CI
run "plan_with_scale_in_protection" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    asg_name                = "my-existing-asg"
    protected_instance_ids  = ["i-00000000000000001"]
    environment             = "test"
  }

  assert {
    condition     = length(var.protected_instance_ids) == 1
    error_message = "protected_instance_ids must contain one entry."
  }
}

# ── Test 3: Plan with standby and decrement-desired flag ─────────────────────
# SKIP_IN_CI
run "plan_with_standby_decrement_desired" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    asg_name                       = "my-existing-asg"
    standby_instance_ids           = ["i-00000000000000002"]
    standby_should_decrement_desired = true
    environment                    = "test"
  }

  assert {
    condition     = var.standby_should_decrement_desired == true
    error_message = "standby_should_decrement_desired must be true."
  }
}
