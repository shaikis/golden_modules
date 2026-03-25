# tests/unit/validation.tftest.hcl — tf-aws-route53
# Confirms that well-formed variable combinations plan without errors.

variables {
  name = "test-r53"
}

# ---------------------------------------------------------------------------
# Minimal valid config — only required var supplied
# ---------------------------------------------------------------------------
run "minimal_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
  }
}

# ---------------------------------------------------------------------------
# Multiple zones in the same plan
# ---------------------------------------------------------------------------
run "multiple_zones" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      public = {
        name    = "example.com"
        comment = "Primary public zone"
      }
      internal = {
        name         = "internal.example.com"
        private_zone = true
        vpc_ids      = ["vpc-0abc123def456789a"]
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Zone with delegation set ID (public zones only)
# ---------------------------------------------------------------------------
run "zone_with_delegation_set" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      main = {
        name              = "example.com"
        delegation_set_id = "N1PA6795SAMPLE"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# name_prefix honoured
# ---------------------------------------------------------------------------
run "name_prefix_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "myapp"
    name_prefix = "prod"
  }
}
