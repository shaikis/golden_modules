# tests/unit/defaults.tftest.hcl — tf-aws-route53
# Verifies feature-gate defaults and zone/record BYO patterns via plan only (free).

variables {
  name = "test-r53"
}

# ---------------------------------------------------------------------------
# Empty zones map — nothing is created by default
# ---------------------------------------------------------------------------
run "no_zones_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
  }

  assert {
    condition     = length(var.zones) == 0
    error_message = "zones must default to an empty map"
  }
}

# ---------------------------------------------------------------------------
# Public zone — private_zone defaults to false
# ---------------------------------------------------------------------------
run "public_zone_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      main = {
        name = "example.com"
      }
    }
  }

  assert {
    condition     = var.zones["main"].private_zone == false
    error_message = "private_zone should default to false for public zones"
  }
}

# ---------------------------------------------------------------------------
# Private zone gate — private_zone = true accepted
# ---------------------------------------------------------------------------
run "private_zone_gate" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      internal = {
        name         = "internal.example.com"
        private_zone = true
        vpc_ids      = ["vpc-0abc123def456789a"]
      }
    }
  }

  assert {
    condition     = var.zones["internal"].private_zone == true
    error_message = "private_zone should be true when explicitly set"
  }
}

# ---------------------------------------------------------------------------
# BYO zone pattern — zone_id provided, no zone creation expected
# ---------------------------------------------------------------------------
run "byo_zone_pattern" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      main = {
        name    = "example.com"
        zone_id = "Z1234567890ABCDEFGHIJ"
      }
    }
  }

  assert {
    condition     = var.zones["main"].zone_id == "Z1234567890ABCDEFGHIJ"
    error_message = "BYO zone_id should be preserved"
  }
}

# ---------------------------------------------------------------------------
# force_destroy defaults to false
# ---------------------------------------------------------------------------
run "force_destroy_default_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      main = {
        name = "example.com"
      }
    }
  }

  assert {
    condition     = var.zones["main"].force_destroy == false
    error_message = "force_destroy should default to false"
  }
}

# ---------------------------------------------------------------------------
# Tags accepted
# ---------------------------------------------------------------------------
run "tags_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    tags = {
      Team = "platform"
    }
  }

  assert {
    condition     = var.tags["Team"] == "platform"
    error_message = "Custom tags should be accepted"
  }
}
