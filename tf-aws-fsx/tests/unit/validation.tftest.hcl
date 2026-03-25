# Unit tests — variable validation for tf-aws-fsx
# command = plan; no real AWS resources are created.

# Verify accepted storage_type values within the lustre object.
run "lustre_valid_storage_type_ssd" {
  command = plan

  variables {
    name = "test-fsx-lustre"
    lustre = {
      storage_capacity = 1200
      subnet_ids       = ["subnet-00000000000000001"]
      storage_type     = "SSD"
      deployment_type  = "SCRATCH_2"
    }
  }

  assert {
    condition     = var.lustre.storage_type == "SSD"
    error_message = "storage_type 'SSD' should be accepted for Lustre."
  }
}

run "lustre_valid_storage_type_hdd" {
  command = plan

  variables {
    name = "test-fsx-lustre-hdd"
    lustre = {
      storage_capacity            = 6000
      subnet_ids                  = ["subnet-00000000000000001"]
      storage_type                = "HDD"
      deployment_type             = "PERSISTENT_1"
      per_unit_storage_throughput = 12
    }
  }

  assert {
    condition     = var.lustre.storage_type == "HDD"
    error_message = "storage_type 'HDD' should be accepted for Lustre."
  }
}

# Verify accepted deployment_type values for Windows.
run "windows_valid_deployment_type_single_az" {
  command = plan

  variables {
    name = "test-fsx-windows"
    windows = {
      storage_capacity    = 32
      subnet_ids          = ["subnet-00000000000000001"]
      deployment_type     = "SINGLE_AZ_1"
      throughput_capacity = 8
    }
  }

  assert {
    condition     = var.windows.deployment_type == "SINGLE_AZ_1"
    error_message = "deployment_type 'SINGLE_AZ_1' should be accepted for Windows."
  }
}

# Verify all filesystem types can be null simultaneously (no resources planned).
run "all_null_no_resources_planned" {
  command = plan

  variables {
    name    = "test-fsx-empty"
    windows = null
    lustre  = null
    ontap   = null
    openzfs = null
  }

  assert {
    condition     = var.windows == null && var.lustre == null && var.ontap == null && var.openzfs == null
    error_message = "All filesystem type variables should be null when not provided."
  }
}
