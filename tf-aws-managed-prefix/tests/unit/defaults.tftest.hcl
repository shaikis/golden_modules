# Unit tests — verify default variable values for tf-aws-managed-prefix
# command = plan; no real AWS resources are created.

run "prefix_list_defaults_empty_entries" {
  command = plan

  variables {
    name         = "test-prefix-list"
    environment  = "dev"
    entries_list = []
  }

  # address_family defaults to IPv4
  assert {
    condition     = var.address_family == "IPv4"
    error_message = "Expected address_family to default to 'IPv4'."
  }

  # allow_replacement defaults to false
  assert {
    condition     = var.allow_replacement == false
    error_message = "Expected allow_replacement to default to false."
  }

  # tags defaults to empty map
  assert {
    condition     = length(var.tags) == 0
    error_message = "Expected tags to default to empty map."
  }

  # entries_list is empty (0 entries)
  assert {
    condition     = length(var.entries_list) == 0
    error_message = "Expected entries_list to be empty."
  }
}
