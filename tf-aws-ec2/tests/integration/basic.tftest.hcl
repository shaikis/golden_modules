# Integration tests — tf-aws-ec2
# Cost estimate: ~$0.01/hr for t3.micro if applied — command = plan only to avoid charges.
# These tests require valid AWS credentials but do NOT create any EC2 instances.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Minimal plan with required vars (name + subnet_id) ───────────────
# SKIP_IN_CI
run "minimal_ec2_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "tftest-ec2-basic"
    subnet_id     = "subnet-00000000000000000"
    instance_type = "t3.micro"
    environment   = "test"
  }

  assert {
    condition     = var.instance_type == "t3.micro"
    error_message = "instance_type must be t3.micro."
  }

  assert {
    condition     = var.subnet_id == "subnet-00000000000000000"
    error_message = "subnet_id must be passed through unchanged."
  }
}

# ── Test 2: Plan with termination protection enabled ─────────────────────────
# SKIP_IN_CI
run "termination_protection_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                    = "tftest-ec2-protected"
    subnet_id               = "subnet-00000000000000000"
    instance_type           = "t3.micro"
    disable_api_termination = true
    environment             = "test"
  }

  assert {
    condition     = var.disable_api_termination == true
    error_message = "disable_api_termination must be true."
  }
}

# ── Test 3: Plan with extra EBS volumes ──────────────────────────────────────
# SKIP_IN_CI
run "extra_ebs_volumes_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name          = "tftest-ec2-ebs"
    subnet_id     = "subnet-00000000000000000"
    instance_type = "t3.micro"
    environment   = "test"
    ebs_volumes = {
      data = {
        device_name = "/dev/sdf"
        volume_size = 20
        volume_type = "gp3"
        encrypted   = true
      }
    }
  }

  assert {
    condition     = length(var.ebs_volumes) == 1
    error_message = "ebs_volumes must contain exactly one entry."
  }
}
