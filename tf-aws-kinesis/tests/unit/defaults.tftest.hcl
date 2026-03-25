# Unit tests — tf-aws-kinesis defaults
# command = plan: no real AWS resources are created.

run "all_feature_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_firehose_streams == false
    error_message = "Expected create_firehose_streams to default to false."
  }

  assert {
    condition     = var.create_analytics_applications == false
    error_message = "Expected create_analytics_applications to default to false."
  }

  assert {
    condition     = var.create_stream_consumers == false
    error_message = "Expected create_stream_consumers to default to false."
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "Expected create_alarms to default to false."
  }
}

run "create_iam_roles_defaults_true" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_iam_roles == true
    error_message = "Expected create_iam_roles to default to true."
  }
}

run "kinesis_streams_defaults_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.kinesis_streams) == 0
    error_message = "Expected kinesis_streams to default to {}."
  }
}

run "collection_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.firehose_streams) == 0
    error_message = "Expected firehose_streams to default to {}."
  }

  assert {
    condition     = length(var.stream_consumers) == 0
    error_message = "Expected stream_consumers to default to {}."
  }

  assert {
    condition     = length(var.analytics_applications) == 0
    error_message = "Expected analytics_applications to default to {}."
  }
}

run "alarm_sns_topic_defaults_null" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.alarm_sns_topic_arn == null
    error_message = "Expected alarm_sns_topic_arn to default to null."
  }
}
