# Unit tests — feature gate defaults, BYO patterns, and empty-map behaviour
# command = plan: these tests never create real AWS resources

# ──────────────────────────────────────────────────────────────────────────────
# Test 1: Default feature gates — only IAM role is created
# ──────────────────────────────────────────────────────────────────────────────
run "default_feature_gates" {
  command = plan

  variables {
    name_prefix = "unit-defaults"
  }

  # create_iam_role defaults to true → role should appear in plan
  assert {
    condition     = length(aws_iam_role.textract) == 1
    error_message = "Expected exactly 1 IAM caller role to be planned when create_iam_role = true (default)."
  }

  assert {
    condition     = length(aws_iam_role.textract_service) == 1
    error_message = "Expected exactly 1 IAM service role to be planned when create_iam_role = true (default)."
  }

  # create_sns_topics defaults to false → no SNS topics
  assert {
    condition     = length(aws_sns_topic.textract) == 0
    error_message = "Expected 0 SNS topics when create_sns_topics = false (default)."
  }

  # create_sqs_queues defaults to false → no SQS queues
  assert {
    condition     = length(aws_sqs_queue.textract) == 0
    error_message = "Expected 0 SQS queues when create_sqs_queues = false (default)."
  }

  # create_alarms defaults to false → no CloudWatch alarms
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sqs_queue_depth) == 0
    error_message = "Expected 0 queue depth alarms when create_alarms = false (default)."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sqs_dlq_depth) == 0
    error_message = "Expected 0 DLQ alarms when create_alarms = false (default)."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 2: Explicit create_iam_role = true → IAM resources planned
# ──────────────────────────────────────────────────────────────────────────────
run "create_iam_role_true" {
  command = plan

  variables {
    name_prefix     = "unit-iam"
    create_iam_role = true
  }

  assert {
    condition     = length(aws_iam_role.textract) == 1
    error_message = "Expected 1 IAM caller role when create_iam_role = true."
  }

  assert {
    condition     = length(aws_iam_role.textract_service) == 1
    error_message = "Expected 1 IAM service role when create_iam_role = true."
  }

  assert {
    condition     = length(aws_iam_role_policy.textract) == 1
    error_message = "Expected 1 inline policy on the caller role when create_iam_role = true."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 3: BYO role_arn — no IAM resources created
# ──────────────────────────────────────────────────────────────────────────────
run "byo_role_arn_no_iam_resources" {
  command = plan

  variables {
    name_prefix     = "unit-byo"
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/existing-textract-role"
  }

  assert {
    condition     = length(aws_iam_role.textract) == 0
    error_message = "Expected 0 IAM caller roles when create_iam_role = false (BYO pattern)."
  }

  assert {
    condition     = length(aws_iam_role.textract_service) == 0
    error_message = "Expected 0 IAM service roles when create_iam_role = false (BYO pattern)."
  }

  assert {
    condition     = length(aws_iam_role_policy.textract) == 0
    error_message = "Expected 0 inline IAM policies when create_iam_role = false (BYO pattern)."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 4: Empty sns_topics map with create_sns_topics = true → no resources
# ──────────────────────────────────────────────────────────────────────────────
run "empty_sns_topics_map" {
  command = plan

  variables {
    name_prefix       = "unit-empty-sns"
    create_sns_topics = true
    sns_topics        = {}
  }

  assert {
    condition     = length(aws_sns_topic.textract) == 0
    error_message = "Expected 0 SNS topics when sns_topics map is empty, even with create_sns_topics = true."
  }

  assert {
    condition     = length(aws_sns_topic_policy.textract) == 0
    error_message = "Expected 0 SNS topic policies when sns_topics map is empty."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 5: Empty sqs_queues map with create_sqs_queues = true → no resources
# ──────────────────────────────────────────────────────────────────────────────
run "empty_sqs_queues_map" {
  command = plan

  variables {
    name_prefix       = "unit-empty-sqs"
    create_sqs_queues = true
    sqs_queues        = {}
  }

  assert {
    condition     = length(aws_sqs_queue.textract) == 0
    error_message = "Expected 0 SQS queues when sqs_queues map is empty, even with create_sqs_queues = true."
  }

  assert {
    condition     = length(aws_sqs_queue.textract_dlq) == 0
    error_message = "Expected 0 DLQ queues when sqs_queues map is empty."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 6: SNS topics populated but create_sns_topics = false → no resources
# ──────────────────────────────────────────────────────────────────────────────
run "sns_topics_gated_by_feature_flag" {
  command = plan

  variables {
    name_prefix       = "unit-gate-sns"
    create_sns_topics = false
    sns_topics = {
      jobs = {
        display_name = "Should not be created"
      }
    }
  }

  assert {
    condition     = length(aws_sns_topic.textract) == 0
    error_message = "Expected 0 SNS topics when create_sns_topics = false, regardless of sns_topics map content."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 7: SQS queues populated but create_sqs_queues = false → no resources
# ──────────────────────────────────────────────────────────────────────────────
run "sqs_queues_gated_by_feature_flag" {
  command = plan

  variables {
    name_prefix       = "unit-gate-sqs"
    create_sqs_queues = false
    sqs_queues = {
      results = {
        create_dlq = true
      }
    }
  }

  assert {
    condition     = length(aws_sqs_queue.textract) == 0
    error_message = "Expected 0 SQS queues when create_sqs_queues = false, regardless of sqs_queues map content."
  }

  assert {
    condition     = length(aws_sqs_queue.textract_dlq) == 0
    error_message = "Expected 0 DLQ queues when create_sqs_queues = false."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 8: Full async pipeline plan — SNS + SQS + alarms all enabled
# ──────────────────────────────────────────────────────────────────────────────
run "full_async_pipeline_plan" {
  command = plan

  variables {
    name_prefix = "unit-full"

    create_sns_topics = true
    sns_topics = {
      jobs = { display_name = "Textract Jobs" }
    }

    create_sqs_queues = true
    sqs_queues = {
      results = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 86400
        create_dlq                 = true
      }
    }

    create_alarms = true

    s3_input_bucket_arns  = ["arn:aws:s3:::my-input-bucket"]
    s3_output_bucket_arns = ["arn:aws:s3:::my-output-bucket"]
  }

  assert {
    condition     = length(aws_sns_topic.textract) == 1
    error_message = "Expected 1 SNS topic in full pipeline plan."
  }

  assert {
    condition     = length(aws_sqs_queue.textract) == 1
    error_message = "Expected 1 SQS queue in full pipeline plan."
  }

  assert {
    condition     = length(aws_sqs_queue.textract_dlq) == 1
    error_message = "Expected 1 DLQ in full pipeline plan (create_dlq = true)."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sqs_queue_depth) == 1
    error_message = "Expected 1 queue depth alarm in full pipeline plan."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sqs_dlq_depth) == 1
    error_message = "Expected 1 DLQ depth alarm in full pipeline plan."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sqs_oldest_message_age) == 1
    error_message = "Expected 1 oldest message age alarm in full pipeline plan."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 9: create_alarms = true but create_sqs_queues = false → no alarms
# ──────────────────────────────────────────────────────────────────────────────
run "alarms_require_sqs_queues" {
  command = plan

  variables {
    name_prefix       = "unit-alarm-no-sqs"
    create_alarms     = true
    create_sqs_queues = false
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sqs_queue_depth) == 0
    error_message = "Expected 0 queue depth alarms when create_sqs_queues = false."
  }
}
