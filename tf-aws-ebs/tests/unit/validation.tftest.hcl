# Unit tests — tf-aws-ebs variable validation
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: gp3 volume type accepted
# ---------------------------------------------------------------------------
run "volume_type_gp3" {
  command = plan

  variables {
    name = "test-ebs-gp3"
    volumes = {
      data = {
        availability_zone = "us-east-1a"
        size              = 20
        type              = "gp3"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.volumes["data"].type == "gp3"
    error_message = "gp3 volume type should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: io1 volume type accepted
# ---------------------------------------------------------------------------
run "volume_type_io1" {
  command = plan

  variables {
    name = "test-ebs-io1"
    volumes = {
      highperf = {
        availability_zone = "us-east-1a"
        size              = 100
        type              = "io1"
        iops              = 3000
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.volumes["highperf"].type == "io1"
    error_message = "io1 volume type should be accepted."
  }

  assert {
    condition     = var.volumes["highperf"].iops == 3000
    error_message = "IOPS should be 3000 for io1."
  }
}

# ---------------------------------------------------------------------------
# Test: sc1 (cold HDD) volume type accepted
# ---------------------------------------------------------------------------
run "volume_type_sc1" {
  command = plan

  variables {
    name = "test-ebs-sc1"
    volumes = {
      cold = {
        availability_zone = "us-east-1a"
        size              = 125
        type              = "sc1"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.volumes["cold"].type == "sc1"
    error_message = "sc1 volume type should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: throughput setting for gp3
# ---------------------------------------------------------------------------
run "volume_throughput_gp3" {
  command = plan

  variables {
    name = "test-ebs-tp"
    volumes = {
      fast = {
        availability_zone = "us-east-1a"
        size              = 50
        type              = "gp3"
        throughput        = 250
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.volumes["fast"].throughput == 250
    error_message = "throughput should be 250 MiB/s."
  }
}

# ---------------------------------------------------------------------------
# Test: Multi-attach enabled flag
# ---------------------------------------------------------------------------
run "multi_attach_enabled" {
  command = plan

  variables {
    name = "test-ebs-ma"
    volumes = {
      shared = {
        availability_zone    = "us-east-1a"
        size                 = 20
        type                 = "io1"
        iops                 = 3000
        multi_attach_enabled = true
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.volumes["shared"].multi_attach_enabled == true
    error_message = "multi_attach_enabled should be true when set."
  }
}

# ---------------------------------------------------------------------------
# Test: DLM schedule interval unit defaults to HOURS
# ---------------------------------------------------------------------------
run "dlm_schedule_interval_unit_default" {
  command = plan

  variables {
    name       = "test-ebs-dlm-unit"
    enable_dlm = true
    dlm_target_tags = {
      "Backup" = "true"
    }
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
    condition     = var.dlm_schedules[0].interval_unit == "HOURS"
    error_message = "Default DLM schedule interval unit should be HOURS."
  }
}
