resource "aws_msk_serverless_cluster" "this" {
  for_each = var.create_serverless_clusters ? var.serverless_clusters : {}

  cluster_name = coalesce(each.value.cluster_name, each.key)

  vpc_config {
    subnet_ids         = each.value.subnet_ids
    security_group_ids = each.value.security_group_ids
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = merge(var.tags, each.value.tags)
}
