# Unit tests — variable validation rules for tf-aws-security-group
# No validation blocks are defined in variables.tf, so these tests focus on
# structural correctness of the ingress/egress rule objects.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Egress rules can be overridden to empty (no default allow-all)
# ---------------------------------------------------------------------------
run "egress_rules_can_be_empty" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name         = "test-sg"
    vpc_id       = "vpc-00000000000000000"
    egress_rules = {}
  }

  assert {
    condition     = var.egress_rules == {}
    error_message = "egress_rules should accept an empty map to lock down outbound traffic."
  }
}

# ---------------------------------------------------------------------------
# Test: Multiple ingress rules with distinct ports are accepted
# ---------------------------------------------------------------------------
run "multiple_ingress_rules_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-sg"
    vpc_id = "vpc-00000000000000000"
    ingress_rules = {
      http = {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
      https = {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }

  assert {
    condition     = length(var.ingress_rules) == 2
    error_message = "Expected exactly two ingress rules."
  }
}

# ---------------------------------------------------------------------------
# Test: name_prefix defaults to empty string
# ---------------------------------------------------------------------------
run "name_prefix_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-sg"
    vpc_id = "vpc-00000000000000000"
  }

  assert {
    condition     = var.name_prefix == ""
    error_message = "name_prefix should default to empty string."
  }
}

# ---------------------------------------------------------------------------
# Test: Self-referencing ingress rule is valid
# ---------------------------------------------------------------------------
run "self_referencing_ingress_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-sg"
    vpc_id = "vpc-00000000000000000"
    ingress_rules = {
      self_all = {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        self      = true
      }
    }
  }

  assert {
    condition     = var.ingress_rules["self_all"].self == true
    error_message = "self-referencing ingress rule should be accepted."
  }
}
