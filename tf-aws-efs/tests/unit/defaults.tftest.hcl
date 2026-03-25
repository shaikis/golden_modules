# Unit tests — verify default variable values for tf-aws-efs
# command = plan; no real AWS resources are created.

run "efs_defaults" {
  command = plan

  variables {
    name        = "efs"
    environment = "dev"
    # create_security_group requires vpc_id; disable it for a pure default check
    create_security_group = false
  }

  # performance_mode defaults to generalPurpose
  assert {
    condition     = var.performance_mode == "generalPurpose"
    error_message = "Expected performance_mode to default to 'generalPurpose'."
  }

  # throughput_mode defaults to elastic
  assert {
    condition     = var.throughput_mode == "elastic"
    error_message = "Expected throughput_mode to default to 'elastic'."
  }

  # backup policy enabled by default
  assert {
    condition     = var.enable_backup_policy == true
    error_message = "Expected enable_backup_policy to default to true."
  }

  # replication disabled by default
  assert {
    condition     = var.enable_replication == false
    error_message = "Expected enable_replication to default to false."
  }

  # encrypted by default
  assert {
    condition     = var.encrypted == true
    error_message = "Expected encrypted to default to true."
  }

  # lifecycle policy enabled by default
  assert {
    condition     = var.enable_lifecycle_policy == true
    error_message = "Expected enable_lifecycle_policy to default to true."
  }

  # transition_to_ia defaults to AFTER_30_DAYS
  assert {
    condition     = var.transition_to_ia == "AFTER_30_DAYS"
    error_message = "Expected transition_to_ia to default to 'AFTER_30_DAYS'."
  }

  # no access points by default
  assert {
    condition     = length(var.access_points) == 0
    error_message = "Expected access_points to default to empty map."
  }
}
