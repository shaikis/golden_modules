# Unit tests — verify default variable values for tf-aws-restore
# command = plan; no real AWS resources are created.

run "restore_defaults_create_iam_role" {
  command = plan

  variables {
    name = "test-restore"
  }

  # create_iam_role defaults to true
  assert {
    condition     = var.create_iam_role == true
    error_message = "Expected create_iam_role to default to true."
  }

  # iam_role_arn defaults to null (BYO not set)
  assert {
    condition     = var.iam_role_arn == null
    error_message = "Expected iam_role_arn to default to null."
  }

  # restore_testing_plans defaults to empty map
  assert {
    condition     = length(var.restore_testing_plans) == 0
    error_message = "Expected restore_testing_plans to default to empty map."
  }

  # restore_testing_selections defaults to empty map
  assert {
    condition     = length(var.restore_testing_selections) == 0
    error_message = "Expected restore_testing_selections to default to empty map."
  }

  # SNS topic not created by default
  assert {
    condition     = var.create_sns_topic == false
    error_message = "Expected create_sns_topic to default to false."
  }

  # CloudWatch alarms not created by default
  assert {
    condition     = var.create_cloudwatch_alarms == false
    error_message = "Expected create_cloudwatch_alarms to default to false."
  }

  # CloudWatch logs disabled by default
  assert {
    condition     = var.enable_cloudwatch_logs == false
    error_message = "Expected enable_cloudwatch_logs to default to false."
  }

  # EC2 restore enabled by default
  assert {
    condition     = var.enable_ec2_restore == true
    error_message = "Expected enable_ec2_restore to default to true."
  }

  # S3 restore disabled by default
  assert {
    condition     = var.enable_s3_restore == false
    error_message = "Expected enable_s3_restore to default to false."
  }
}

run "restore_byo_iam_role_pattern" {
  command = plan

  variables {
    name            = "test-restore-byo"
    create_iam_role = false
    iam_role_arn    = "arn:aws:iam::123456789012:role/my-existing-restore-role"
  }

  assert {
    condition     = var.create_iam_role == false
    error_message = "Expected create_iam_role to be false when BYO pattern is used."
  }

  assert {
    condition     = var.iam_role_arn == "arn:aws:iam::123456789012:role/my-existing-restore-role"
    error_message = "Expected iam_role_arn to be the BYO ARN value."
  }
}
