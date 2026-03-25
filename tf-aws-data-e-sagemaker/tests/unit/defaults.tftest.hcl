# Unit test: verify feature-gate defaults and BYO IAM/KMS pattern.
# command = plan — no AWS resources are created.

variables {
  # Minimum required variable — no domains, pipelines, models, etc.
  name_prefix = "test"
  tags = {
    Environment = "test"
  }
}

# ── Test 1: All feature gates default to false ────────────────────────────────
run "feature_gates_default_to_false" {
  command = plan

  module {
    source = "../../"
  }

  # No feature maps supplied — all gates must stay closed.
  assert {
    condition     = var.create_pipelines == false
    error_message = "create_pipelines must default to false."
  }

  assert {
    condition     = var.create_models == false
    error_message = "create_models must default to false."
  }

  assert {
    condition     = var.create_endpoints == false
    error_message = "create_endpoints must default to false."
  }

  assert {
    condition     = var.create_feature_groups == false
    error_message = "create_feature_groups must default to false."
  }

  assert {
    condition     = var.create_user_profiles == false
    error_message = "create_user_profiles must default to false."
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms must default to false."
  }
}

# ── Test 2: BYO role disables auto-create ─────────────────────────────────────
run "byo_role_disables_auto_create" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test-sagemaker-role"
  }

  assert {
    condition     = var.create_iam_role == false
    error_message = "create_iam_role should be false when BYO role is supplied."
  }

  assert {
    condition     = var.role_arn == "arn:aws:iam::123456789012:role/test-sagemaker-role"
    error_message = "role_arn should be the BYO role ARN."
  }
}

# ── Test 3: BYO KMS key is accepted ───────────────────────────────────────────
run "byo_kms_key_is_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }

  assert {
    condition     = var.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abc"
    error_message = "kms_key_arn should be passed through correctly."
  }
}

# ── Test 4: Pipelines gate — no pipelines created without flag ────────────────
run "pipelines_not_created_without_gate" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_pipelines = false
    pipelines        = {}
  }

  assert {
    condition     = var.create_pipelines == false
    error_message = "Pipelines should remain disabled when create_pipelines = false."
  }
}

# ── Test 5: Alarms gate defaults off, SNS topic not required ─────────────────
run "alarms_off_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "Alarms must be off by default."
  }

  assert {
    condition     = var.alarm_sns_topic_arn == null
    error_message = "alarm_sns_topic_arn must default to null."
  }
}
