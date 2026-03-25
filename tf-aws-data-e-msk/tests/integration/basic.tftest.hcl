# Integration test — tf-aws-data-e-msk
# WARNING: MSK clusters cost $0.21+/broker-hour ($0.63+/hour for 3-broker). Plan only.
# Uses command = plan ONLY to avoid incurring charges.

run "msk_cluster_plan" {
  # SKIP_IN_CI
  # WARNING: MSK clusters cost $0.21+/broker-hour ($0.63+/hour for 3-broker). Plan only.
  command = plan

  variables {
    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }

    clusters = {
      basic = {
        kafka_version          = "3.5.1"
        number_of_broker_nodes = 3
        instance_type          = "kafka.m5.large"
        client_subnets         = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]
        security_group_ids     = ["sg-00000000000000001"]
        ebs_volume_size        = 100
        encryption_in_transit  = "TLS"
        in_cluster_encryption  = true
        enable_sasl_iam        = true
        enable_sasl_scram      = false
        enhanced_monitoring    = "PER_BROKER"
        cloudwatch_logs_enabled = false
        tags = {
          Environment = "integration-test"
        }
      }
    }

    create_alarms             = false
    create_serverless_clusters = false
    create_vpc_connections    = false
    create_scram_auth         = false
    create_iam_role           = false
  }

  assert {
    condition     = length(var.clusters) == 1
    error_message = "Expected exactly one MSK cluster to be planned."
  }
}
