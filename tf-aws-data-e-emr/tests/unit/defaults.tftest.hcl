# Unit test: verify feature-gate defaults and BYO IAM/KMS pattern for tf-aws-data-e-emr
# command = plan  →  free, no AWS resources are created

variables {
  tags = { env = "test" }
}

# ── Gate defaults ─────────────────────────────────────────────────────────────

run "feature_gates_default_to_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_serverless_applications == false
    error_message = "create_serverless_applications must default to false"
  }

  assert {
    condition     = var.create_security_configurations == false
    error_message = "create_security_configurations must default to false"
  }

  assert {
    condition     = var.create_studios == false
    error_message = "create_studios must default to false"
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms must default to false"
  }
}

run "iam_role_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_iam_role == true
    error_message = "create_iam_role must default to true"
  }
}

# ── BYO pattern ───────────────────────────────────────────────────────────────

run "byo_fields_default_to_null" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.role_arn == null
    error_message = "role_arn must default to null"
  }

  assert {
    condition     = var.instance_profile_arn == null
    error_message = "instance_profile_arn must default to null"
  }

  assert {
    condition     = var.kms_key_arn == null
    error_message = "kms_key_arn must default to null"
  }

  assert {
    condition     = var.alarm_sns_topic_arn == null
    error_message = "alarm_sns_topic_arn must default to null"
  }
}

run "byo_role_arns_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_iam_role      = false
    role_arn             = "arn:aws:iam::123456789012:role/emr-service-role"
    instance_profile_arn = "arn:aws:iam::123456789012:instance-profile/emr-ec2-profile"
  }

  assert {
    condition     = var.role_arn == "arn:aws:iam::123456789012:role/emr-service-role"
    error_message = "BYO service role ARN was not accepted"
  }

  assert {
    condition     = var.instance_profile_arn == "arn:aws:iam::123456789012:instance-profile/emr-ec2-profile"
    error_message = "BYO instance profile ARN was not accepted"
  }
}

# ── Collection defaults ───────────────────────────────────────────────────────

run "optional_collections_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.clusters) == 0
    error_message = "clusters must default to empty map"
  }

  assert {
    condition     = length(var.serverless_applications) == 0
    error_message = "serverless_applications must default to empty map"
  }

  assert {
    condition     = length(var.security_configurations) == 0
    error_message = "security_configurations must default to empty map"
  }

  assert {
    condition     = length(var.studios) == 0
    error_message = "studios must default to empty map"
  }
}
