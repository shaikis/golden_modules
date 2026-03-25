# Integration tests — basic transit gateway for tf-aws-transit-gateway
# Creates real AWS resources; always destroyed after the run block completes.
# NOTE: Transit Gateway incurs hourly charges even with zero attachments.
# Requires valid AWS credentials in the environment.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Deploy a minimal TGW with no attachments or custom route tables # SKIP_IN_CI
# ---------------------------------------------------------------------------
run "basic_tgw_apply" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name            = "tftest-tgw"
    amazon_side_asn = 64999
    environment     = "test"

    # No VPC attachments, no custom route tables
    vpc_attachments  = {}
    tgw_route_tables = {}
    tgw_routes       = {}
    ram_share_enabled = false

    tags = {
      ManagedBy = "terraform-test"
    }
  }

  # TGW ID is non-empty
  assert {
    condition     = length(module.this.tgw_id) > 4
    error_message = "tgw_id should be a non-empty identifier."
  }

  # ARN is populated
  assert {
    condition     = can(regex("^arn:", module.this.tgw_arn))
    error_message = "tgw_arn should start with 'arn:'."
  }

  # No custom route tables created
  assert {
    condition     = length(module.this.route_table_ids) == 0
    error_message = "No custom route tables should be created when tgw_route_tables is empty."
  }

  # No VPC attachments created
  assert {
    condition     = length(module.this.vpc_attachment_ids) == 0
    error_message = "No VPC attachments should be created when vpc_attachments is empty."
  }

  # RAM share ARN is null when not sharing
  assert {
    condition     = module.this.ram_share_arn == null
    error_message = "ram_share_arn should be null when ram_share_enabled = false."
  }
}
