# ---------------------------------------------------------------------------
# MSK Replicator — cross-region Kafka topic replication
# Used for active-passive or active-active multi-region payment architectures
# ---------------------------------------------------------------------------

resource "aws_msk_replicator" "this" {
  for_each = var.replicators

  replicator_name            = each.key
  description                = each.value.description
  service_execution_role_arn = each.value.service_execution_role_arn != null ? each.value.service_execution_role_arn : aws_iam_role.replicator[each.key].arn

  kafka_cluster {
    amazon_msk_cluster {
      msk_cluster_arn = each.value.source_cluster_arn
    }
    vpc_config {
      subnet_ids         = each.value.source_subnet_ids
      security_group_ids = each.value.source_security_group_ids
    }
  }

  kafka_cluster {
    amazon_msk_cluster {
      msk_cluster_arn = each.value.target_cluster_arn
    }
    vpc_config {
      subnet_ids         = each.value.target_subnet_ids
      security_group_ids = each.value.target_security_group_ids
    }
  }

  replication_info_list {
    source_kafka_cluster_arn = each.value.source_cluster_arn
    target_kafka_cluster_arn = each.value.target_cluster_arn

    target_compression_type = each.value.target_compression_type

    dynamic "topic_replication" {
      for_each = [each.value.topic_replication]
      content {
        topics_to_replicate                       = topic_replication.value.topics_to_replicate
        topics_to_exclude                         = topic_replication.value.topics_to_exclude
        detect_and_copy_new_topics                = topic_replication.value.detect_and_copy_new_topics
        copy_access_control_lists_for_topics      = topic_replication.value.copy_access_control_lists_for_topics
        copy_topic_configurations                 = topic_replication.value.copy_topic_configurations
        starting_position {
          type = topic_replication.value.starting_position_type
        }
      }
    }

    dynamic "consumer_group_replication" {
      for_each = each.value.consumer_group_replication != null ? [each.value.consumer_group_replication] : []
      content {
        consumer_groups_to_replicate = consumer_group_replication.value.consumer_groups_to_replicate
        consumer_groups_to_exclude   = consumer_group_replication.value.consumer_groups_to_exclude
        detect_and_copy_new_consumer_groups  = consumer_group_replication.value.detect_and_copy_new_consumer_groups
        synchronise_consumer_group_offsets   = consumer_group_replication.value.synchronise_consumer_group_offsets
      }
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# ---------------------------------------------------------------------------
# Auto-created IAM role for MSK Replicator (when service_execution_role_arn
# is not provided)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "replicator" {
  for_each = {
    for k, v in var.replicators : k => v
    if v.service_execution_role_arn == null
  }

  name = "msk-replicator-${each.key}-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "kafka.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "replicator" {
  for_each = {
    for k, v in var.replicators : k => v
    if v.service_execution_role_arn == null
  }

  name = "msk-replicator-policy"
  role = aws_iam_role.replicator[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSourceCluster"
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:ReadData",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeClusterDynamicConfiguration",
          "kafka-cluster:DescribeTopicDynamicConfiguration",
        ]
        Resource = [
          each.value.source_cluster_arn,
          "${each.value.source_cluster_arn}/*",
          replace(each.value.source_cluster_arn, ":cluster/", ":topic/"),
          replace(each.value.source_cluster_arn, ":cluster/", ":group/"),
        ]
      },
      {
        Sid    = "WriteTargetCluster"
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:WriteData",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:AlterTopic",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeClusterDynamicConfiguration",
          "kafka-cluster:AlterClusterDynamicConfiguration",
          "kafka-cluster:DescribeTopicDynamicConfiguration",
          "kafka-cluster:AlterTopicDynamicConfiguration",
        ]
        Resource = [
          each.value.target_cluster_arn,
          "${each.value.target_cluster_arn}/*",
          replace(each.value.target_cluster_arn, ":cluster/", ":topic/"),
          replace(each.value.target_cluster_arn, ":cluster/", ":group/"),
        ]
      },
      {
        Sid      = "DescribeNetworking"
        Effect   = "Allow"
        Action   = ["ec2:DescribeVpcs", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups"]
        Resource = "*"
      },
      {
        Sid    = "CreateNetworkInterfaces"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
        ]
        Resource = "*"
      }
    ]
  })
}
