# SKIP_IN_CI
# Integration test — tf-aws-managed-prefix
# command = apply; creates a real AWS Managed Prefix List.
# Cost: Prefix lists are free. Destroy immediately after testing.
# Set AWS_PROFILE / AWS credentials before running.

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "tftest-prefix-basic"
  environment = "test"

  entries_list = [
    "10.10.0.0/16",
    "172.16.0.0/12",
  ]

  address_family   = "IPv4"
  allow_replacement = false

  tags = {
    ManagedBy   = "terraform-test"
    Environment = "test"
  }
}

run "create_prefix_list" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.id != null && output.id != ""
    error_message = "Expected prefix list id (output.id) to be set after apply."
  }

  assert {
    condition     = length(output.entries) == 2
    error_message = "Expected exactly 2 entries in the prefix list."
  }
}
