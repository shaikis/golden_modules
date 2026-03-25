# Unit tests — tf-aws-ebs defaults and BYO patterns
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: Minimal volume creation with defaults
# ---------------------------------------------------------------------------
run "defaults_plan_succeeds" {
  command = plan

  variables {
    name = "test-ebs"
    volumes = {
      data = {
        availability_zone = "us-east-1a"
        size              = 20
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.volumes["data"].type == "gp3"
    error_message = "Default volume type should be gp3."
  }

  assert {
    condition     = var.volumes["data"].multi_attach_enabled == false
    error_message = "multi_attach_enabled should be false by default."
  }

  assert {
    condition     = var.volumes["data"].final_snapshot == false
    error_message = "final_snapshot should be false by default."
  }
}

# ---------------------------------------------------------------------------
# Test: DLM lifecycle policy disabled by default
# ---------------------------------------------------------------------------
run "dlm_disabled_by_default" {
  command = plan

  variables {
    name = "test-ebs-dlm"
    volumes = {
      logs = {
        availability_zone = "us-east-1a"
        size              = 50
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_dlm == false
    error_message = "DLM lifecycle policy should be disabled by default."
  }
}

# ---------------------------------------------------------------------------
# Test: DLM lifecycle policy enabled
# ---------------------------------------------------------------------------
run "dlm_enabled" {
  command = plan

  variables {
    name       = "test-ebs-dlm-on"
    enable_dlm = true
    dlm_target_tags = {
      "Backup" = "true"
    }
    dlm_schedules = [
      {
        name         = "daily"
        interval     = 24
        times        = ["02:00"]
        retain_count = 7
      }
    ]
    volumes = {
      app = {
        availability_zone = "us-east-1a"
        size              = 100
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_dlm == true
    error_message = "enable_dlm should be true when enabled."
  }

  assert {
    condition     = length(var.dlm_schedules) == 1
    error_message = "One DLM schedule should be defined."
  }
}

# ---------------------------------------------------------------------------
# Test: BYO KMS key for volume encryption
# ---------------------------------------------------------------------------
run "byo_kms_key" {
  command = plan

  variables {
    name        = "test-ebs-kms"
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
    volumes = {
      secure = {
        availability_zone = "us-east-1a"
        size              = 20
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
    error_message = "BYO KMS key ARN should be passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# Test: Volume attachments default to empty
# ---------------------------------------------------------------------------
run "volume_attachments_empty_by_default" {
  command = plan

  variables {
    name = "test-ebs-attach"
    volumes = {
      root = {
        availability_zone = "us-east-1a"
        size              = 20
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.volume_attachments) == 0
    error_message = "volume_attachments should be empty by default."
  }
}

# ---------------------------------------------------------------------------
# Test: Snapshots default to empty
# ---------------------------------------------------------------------------
run "snapshots_empty_by_default" {
  command = plan

  variables {
    name = "test-ebs-snaps"
    volumes = {
      data = {
        availability_zone = "us-east-1a"
        size              = 20
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.snapshots) == 0
    error_message = "snapshots should be empty by default."
  }

  assert {
    condition     = length(var.snapshot_copy) == 0
    error_message = "snapshot_copy should be empty by default."
  }
}

# ---------------------------------------------------------------------------
# Test: DLM target resource type default
# ---------------------------------------------------------------------------
run "dlm_target_resource_type_default" {
  command = plan

  variables {
    name = "test-ebs-dlmt"
    volumes = {
      data = {
        availability_zone = "us-east-1a"
        size              = 20
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.dlm_target_resource_type == "VOLUME"
    error_message = "Default DLM target resource type should be VOLUME."
  }
}
