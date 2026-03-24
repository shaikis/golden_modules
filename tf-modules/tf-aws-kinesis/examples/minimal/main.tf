# Minimal Kinesis setup — one ON_DEMAND stream with KMS encryption.
# No Firehose, no analytics, no alarms, no IAM roles created.
# Enable feature flags incrementally as your pipeline grows.

module "kinesis" {
  source = "../../"

  kinesis_streams = {
    events = {
      on_demand = true # auto-scales, no shard management needed
    }
  }

  # Everything else is disabled by default:
  # create_firehose_streams       = false  (default)
  # create_analytics_applications = false  (default)
  # create_stream_consumers       = false  (default)
  # create_alarms                 = false  (default)
  create_iam_roles = false
}

output "stream_arns" {
  value = module.kinesis.stream_arns
}
