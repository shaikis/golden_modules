# Complete example: 2 provisioned clusters + 1 serverless cluster
# Demonstrates: all alarms, SASL/IAM + SCRAM auth, tiered storage,
# Prometheus monitoring, custom MSK configuration, VPC connections.

module "msk" {
  source = "../../"

  # Feature gates
  create_alarms              = true
  create_serverless_clusters = true
  create_scram_auth          = true
  create_vpc_connections     = false # requires cross-account setup
  create_iam_role            = true

  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  kms_key_arn         = var.kms_key_arn

  # Alarm thresholds
  alarm_disk_used_percent_threshold   = 70
  alarm_memory_used_percent_threshold = 80
  alarm_cpu_user_threshold            = 60
  alarm_evaluation_periods            = 3
  alarm_period_seconds                = 300

  # IAM principals allowed to assume producer/consumer roles
  iam_producer_assume_role_principals = [
    "arn:aws:iam::123456789012:role/app-producer",
  ]
  iam_consumer_assume_role_principals = [
    "arn:aws:iam::123456789012:role/app-consumer",
  ]

  # MSK cluster configurations
  configurations = {
    prod-config = {
      name              = "prod-kafka-config"
      description       = "Production Kafka broker configuration"
      kafka_versions    = ["3.5.1"]
      server_properties = <<-EOT
        auto.create.topics.enable=false
        log.retention.hours=168
        default.replication.factor=3
        min.insync.replicas=2
        compression.type=lz4
        num.partitions=12
        log.segment.bytes=536870912
        message.max.bytes=10485760
        replica.fetch.max.bytes=10485760
        log.retention.check.interval.ms=300000
      EOT
    }
  }

  # Provisioned clusters
  clusters = {
    # High-throughput event streaming cluster with tiered storage
    events = {
      kafka_version          = "3.5.1"
      number_of_broker_nodes = 3
      instance_type          = "kafka.m5.xlarge"
      client_subnets         = ["subnet-aaa1", "subnet-bbb1", "subnet-ccc1"]
      security_group_ids     = ["sg-events-msk"]

      ebs_volume_size                    = 500
      provisioned_throughput_enabled     = true
      provisioned_throughput_volume_mbps = 500

      encryption_in_transit = "TLS"
      in_cluster_encryption = true

      enable_sasl_iam   = true
      enable_sasl_scram = true

      enhanced_monitoring = "PER_TOPIC_PER_BROKER"

      # Tiered storage for long-term retention at lower cost
      tiered_storage_enabled = true
      storage_mode           = "TIERED"

      # Prometheus monitoring
      jmx_exporter_enabled  = true
      node_exporter_enabled = true

      # CloudWatch logging
      cloudwatch_logs_enabled = true
      log_group               = "/aws/msk/events"

      configuration_key = "prod-config"

      tags = {
        Cluster     = "events"
        Environment = "production"
        CostCenter  = "platform"
      }
    }

    # CDC / analytics cluster — smaller, cost optimised
    analytics = {
      kafka_version          = "3.5.1"
      number_of_broker_nodes = 3
      instance_type          = "kafka.m5.large"
      client_subnets         = ["subnet-aaa2", "subnet-bbb2", "subnet-ccc2"]
      security_group_ids     = ["sg-analytics-msk"]

      ebs_volume_size = 200

      encryption_in_transit = "TLS"
      in_cluster_encryption = true

      enable_sasl_iam   = true
      enable_sasl_scram = false

      enhanced_monitoring = "PER_BROKER"

      jmx_exporter_enabled  = true
      node_exporter_enabled = false

      cloudwatch_logs_enabled = true
      log_group               = "/aws/msk/analytics"

      s3_logs_enabled = true
      s3_logs_bucket  = "my-msk-logs-bucket"
      s3_logs_prefix  = "analytics/"

      configuration_key = "prod-config"

      tags = {
        Cluster     = "analytics"
        Environment = "production"
        CostCenter  = "data"
      }
    }
  }

  # MSK Serverless cluster for variable workloads / dev streams
  serverless_clusters = {
    dev-streams = {
      cluster_name       = "dev-streams-serverless"
      subnet_ids         = ["subnet-dev1", "subnet-dev2"]
      security_group_ids = ["sg-dev-msk"]
      tags = {
        Environment = "development"
      }
    }
  }

  # SCRAM auth secret associations
  scram_associations = {
    events-scram = {
      cluster_key = "events"
      secret_arn_list = [
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:msk/events/legacy-producer",
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:msk/events/legacy-consumer",
      ]
    }
  }

  tags = {
    Project     = "data-platform"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
