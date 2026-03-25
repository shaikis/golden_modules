# Unit tests — defaults and feature gates for tf-aws-security-group
# Runs as plan-only; no AWS resources are created.

variables {
  name   = "test-sg"
  vpc_id = "vpc-00000000000000000"
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Ingress rules default to empty map
# ---------------------------------------------------------------------------
run "ingress_rules_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.ingress_rules == {}
    error_message = "ingress_rules should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: Egress rules default to allow-all-outbound
# ---------------------------------------------------------------------------
run "egress_rules_default_allow_all" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = contains(keys(var.egress_rules), "all_outbound")
    error_message = "egress_rules should contain a default 'all_outbound' rule."
  }
}

# ---------------------------------------------------------------------------
# Test: Default egress rule allows all protocols
# ---------------------------------------------------------------------------
run "egress_default_rule_protocol" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.egress_rules["all_outbound"].protocol == "-1"
    error_message = "Default egress rule protocol should be '-1' (all)."
  }
}

# ---------------------------------------------------------------------------
# Test: revoke_rules_on_delete defaults to true
# ---------------------------------------------------------------------------
run "revoke_rules_on_delete_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.revoke_rules_on_delete == true
    error_message = "revoke_rules_on_delete should default to true."
  }
}

# ---------------------------------------------------------------------------
# Test: description defaults to 'Managed by Terraform'
# ---------------------------------------------------------------------------
run "description_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.description == "Managed by Terraform"
    error_message = "description should default to 'Managed by Terraform'."
  }
}

# ---------------------------------------------------------------------------
# Test: environment defaults to dev
# ---------------------------------------------------------------------------
run "environment_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "environment should default to 'dev'."
  }
}

# ---------------------------------------------------------------------------
# Test: Additional ingress rules can be specified
# ---------------------------------------------------------------------------
run "custom_ingress_rules_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-sg"
    vpc_id = "vpc-00000000000000000"
    ingress_rules = {
      https = {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTPS from anywhere"
      }
    }
  }

  assert {
    condition     = contains(keys(var.ingress_rules), "https")
    error_message = "Custom ingress rule 'https' should be present."
  }
}

# ---------------------------------------------------------------------------
# Test: tags default to empty map
# ---------------------------------------------------------------------------
run "tags_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.tags == {}
    error_message = "tags should default to an empty map."
  }
}
