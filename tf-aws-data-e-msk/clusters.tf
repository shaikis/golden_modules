locals {
  # Default Kafka broker properties merged with per-cluster overrides
  default_server_properties = {
    "auto.create.topics.enable"       = "false"
    "log.retention.hours"             = "168"
    "default.replication.factor"      = "3"
    "min.insync.replicas"             = "2"
    "compression.type"                = "producer"
    "num.partitions"                  = "6"
    "log.segment.bytes"               = "1073741824"
    "log.retention.check.interval.ms" = "300000"
  }
}

resource "aws_msk_cluster" "this" {
  for_each = var.clusters

  cluster_name           = each.key
  kafka_version          = each.value.kafka_version
  number_of_broker_nodes = each.value.number_of_broker_nodes
  enhanced_monitoring    = each.value.enhanced_monitoring

  storage_mode = each.value.tiered_storage_enabled ? "TIERED" : each.value.storage_mode

  broker_node_group_info {
    instance_type   = each.value.instance_type
    client_subnets  = each.value.client_subnets
    security_groups = each.value.security_group_ids

    storage_info {
      ebs_storage_info {
        volume_size = each.value.ebs_volume_size

        dynamic "provisioned_throughput" {
          for_each = each.value.provisioned_throughput_enabled ? [1] : []
          content {
            enabled           = true
            volume_throughput = each.value.provisioned_throughput_volume_mbps
          }
        }
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = each.value.encryption_in_transit
      in_cluster    = each.value.in_cluster_encryption
    }
    encryption_at_rest_kms_key_arn = each.value.tiered_storage_enabled ? null : var.kms_key_arn
  }

  client_authentication {
    unauthenticated = each.value.unauthenticated

    sasl {
      scram = each.value.enable_sasl_scram
      iam   = each.value.enable_sasl_iam
    }

    dynamic "tls" {
      for_each = length(each.value.certificate_authority_arns) > 0 ? [1] : []
      content {
        certificate_authority_arns = each.value.certificate_authority_arns
      }
    }
  }

  dynamic "configuration_info" {
    for_each = each.value.configuration_key != null ? [each.value.configuration_key] : []
    content {
      arn      = aws_msk_configuration.this[configuration_info.value].arn
      revision = aws_msk_configuration.this[configuration_info.value].latest_revision
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = each.value.jmx_exporter_enabled
      }
      node_exporter {
        enabled_in_broker = each.value.node_exporter_enabled
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = each.value.cloudwatch_logs_enabled
        log_group = each.value.log_group
      }

      firehose {
        enabled         = each.value.firehose_logs_enabled
        delivery_stream = each.value.firehose_delivery_stream
      }

      s3 {
        enabled = each.value.s3_logs_enabled
        bucket  = each.value.s3_logs_bucket
        prefix  = each.value.s3_logs_prefix
      }
    }
  }

  tags = merge(var.tags, each.value.tags)
}
