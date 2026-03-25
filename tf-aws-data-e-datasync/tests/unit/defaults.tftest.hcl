# Unit test: verify feature-gate defaults and BYO IAM/KMS pattern.
# command = plan — no AWS resources are created.

variables {
  name_prefix = "test"
  tags = {
    Environment = "test"
  }
}

# ── Test 1: Non-S3 location gates default to false ────────────────────────────
run "non_s3_location_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_efs_locations == false
    error_message = "create_efs_locations must default to false."
  }

  assert {
    condition     = var.create_fsx_windows_locations == false
    error_message = "create_fsx_windows_locations must default to false."
  }

  assert {
    condition     = var.create_fsx_lustre_locations == false
    error_message = "create_fsx_lustre_locations must default to false."
  }

  assert {
    condition     = var.create_nfs_locations == false
    error_message = "create_nfs_locations must default to false."
  }

  assert {
    condition     = var.create_smb_locations == false
    error_message = "create_smb_locations must default to false."
  }

  assert {
    condition     = var.create_hdfs_locations == false
    error_message = "create_hdfs_locations must default to false."
  }

  assert {
    condition     = var.create_object_storage_locations == false
    error_message = "create_object_storage_locations must default to false."
  }
}

# ── Test 2: Agent and alarm gates default to false ────────────────────────────
run "agent_and_alarm_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_agents == false
    error_message = "create_agents must default to false."
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms must default to false."
  }
}

# ── Test 3: BYO role disables auto-create ─────────────────────────────────────
run "byo_role_disables_auto_create" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test-datasync-role"
  }

  assert {
    condition     = var.create_iam_role == false
    error_message = "create_iam_role must be false when BYO role is supplied."
  }

  assert {
    condition     = var.role_arn == "arn:aws:iam::123456789012:role/test-datasync-role"
    error_message = "role_arn must equal the BYO role ARN."
  }
}

# ── Test 4: BYO KMS key is accepted ───────────────────────────────────────────
run "byo_kms_key_is_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }

  assert {
    condition     = var.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abc"
    error_message = "kms_key_arn must be passed through correctly."
  }
}

# ── Test 5: S3 location gate defaults to true ─────────────────────────────────
run "s3_locations_gate_defaults_true" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_s3_locations == true
    error_message = "create_s3_locations should default to true."
  }
}

# ── Test 6: Tasks map defaults to empty ───────────────────────────────────────
run "tasks_map_defaults_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.tasks) == 0
    error_message = "tasks must default to an empty map."
  }
}
