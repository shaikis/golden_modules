# Unit tests — variable validation for tf-aws-managed-prefix
# command = plan; no real AWS resources are created.

run "valid_ipv4_cidrs_accepted" {
  command = plan

  variables {
    name         = "test-prefix-valid"
    environment  = "dev"
    entries_list = ["10.0.0.0/8", "192.168.1.0/24"]
    address_family = "IPv4"
  }

  assert {
    condition     = length(var.entries_list) == 2
    error_message = "Expected 2 valid IPv4 CIDR entries to be accepted."
  }
}

run "valid_ipv6_cidrs_accepted" {
  command = plan

  variables {
    name           = "test-prefix-ipv6"
    environment    = "dev"
    entries_list   = ["2001:db8::/32"]
    address_family = "IPv6"
  }

  assert {
    condition     = var.address_family == "IPv6"
    error_message = "address_family 'IPv6' should be accepted."
  }
}

# Negative test: invalid CIDR format must be rejected by the validation block.
run "invalid_cidr_rejected" {
  command = plan

  variables {
    name         = "test-prefix-invalid"
    environment  = "dev"
    entries_list = ["not-a-cidr"]
  }

  expect_failures = [
    var.entries_list,
  ]
}

# Negative test: invalid address_family must be rejected.
run "invalid_address_family_rejected" {
  command = plan

  variables {
    name           = "test-prefix-bad-af"
    environment    = "dev"
    entries_list   = ["10.0.0.0/8"]
    address_family = "IPvX"
  }

  expect_failures = [
    var.address_family,
  ]
}
