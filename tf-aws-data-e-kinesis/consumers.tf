# ---------------------------------------------------------------------------
# Enhanced Fan-Out Consumers
# ---------------------------------------------------------------------------
# Enhanced fan-out (EFO) consumers receive dedicated throughput of 2 MB/s
# per shard (vs shared 2 MB/s per shard across all standard consumers).
# Each shard supports up to 20 registered EFO consumers.
# ---------------------------------------------------------------------------
# NOTE: aws_kinesis_stream_consumer resources are defined in streams.tf.
#       This file contains supplemental locals and outputs for consumers.
# ---------------------------------------------------------------------------

locals {
  # Flatten all consumer ARNs keyed by consumer map key
  consumer_arn_map = {
    for k, v in aws_kinesis_stream_consumer.this : k => v.arn
  }

  # Consumer ARN lookup by stream key — useful for downstream references
  consumer_arns_by_stream = {
    for k, v in var.stream_consumers : v.stream_key => aws_kinesis_stream_consumer.this[k].arn...
  }
}
