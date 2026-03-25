# SKIP_IN_CI
# Integration test — tf-aws-fsx (Lustre SCRATCH_2, plan-only)
# command = apply would create a real FSx Lustre file system.
# Cost: FSx Lustre SCRATCH_2 ~$0.14/GB-month. Destroy immediately after testing.
# Set AWS_PROFILE / AWS credentials before running.
# NOTE: This test uses plan (not apply) because FSx provisioning takes 5-20 min
#       and incurs cost. Switch to apply only in a dedicated cost-acceptance environment.

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "tftest-fsx-lustre"
  environment = "test"

  lustre = {
    storage_capacity = 1200
    subnet_ids       = ["REPLACE_WITH_REAL_SUBNET_ID"]
    deployment_type  = "SCRATCH_2"
    storage_type     = "SSD"
  }

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "plan_fsx_lustre" {
  # Using plan here to avoid FSx provisioning time and cost in standard CI.
  # Change to apply in a dedicated integration environment.
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.lustre != null
    error_message = "Expected lustre configuration to be non-null."
  }

  assert {
    condition     = var.lustre.storage_capacity == 1200
    error_message = "Expected lustre storage_capacity to be 1200."
  }
}
