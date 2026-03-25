locals {
  # Resolve subnet group names: prefer module-created, else fall back to key as literal name
  cluster_subnet_group_names = {
    for k, v in var.clusters :
    k => (
      v.subnet_group_key != null && var.create_subnet_groups && contains(keys(var.subnet_groups), v.subnet_group_key)
      ? aws_redshift_subnet_group.this[v.subnet_group_key].name
      : v.subnet_group_key
    )
  }

  # Resolve parameter group names
  cluster_parameter_group_names = {
    for k, v in var.clusters :
    k => (
      v.parameter_group_key != null && var.create_parameter_groups && contains(keys(var.parameter_groups), v.parameter_group_key)
      ? aws_redshift_parameter_group.this[v.parameter_group_key].name
      : v.parameter_group_key
    )
  }

  # Resolve IAM role ARNs for each cluster
  cluster_iam_role_arns = {
    for k, v in var.clusters :
    k => distinct(concat(
      # Module-created role (when create_iam_role = true)
      var.create_iam_role ? [aws_iam_role.redshift[0].arn] : [],
      # BYO role from variable
      var.role_arn != null ? [var.role_arn] : [],
      # Additional explicit ARNs from the cluster config
      v.additional_iam_role_arns,
    ))
  }
}

resource "aws_redshift_cluster" "this" {
  for_each = var.clusters

  cluster_identifier = each.key
  database_name      = each.value.database_name
  master_username    = each.value.master_username

  # Password management
  manage_master_password = each.value.manage_master_password
  master_password        = each.value.manage_master_password ? null : each.value.master_password

  # Node configuration
  node_type       = each.value.node_type
  cluster_type    = each.value.cluster_type
  number_of_nodes = each.value.cluster_type == "single-node" ? null : each.value.number_of_nodes

  # Networking
  cluster_subnet_group_name            = local.cluster_subnet_group_names[each.key]
  cluster_parameter_group_name         = local.cluster_parameter_group_names[each.key]
  vpc_security_group_ids               = each.value.vpc_security_group_ids
  enhanced_vpc_routing                 = each.value.enhanced_vpc_routing
  publicly_accessible                  = each.value.publicly_accessible
  availability_zone                    = each.value.availability_zone
  availability_zone_relocation_enabled = each.value.availability_zone_relocation_enabled
  elastic_ip                           = each.value.elastic_ip

  # Encryption
  encrypted  = each.value.encrypted
  kms_key_id = coalesce(each.value.kms_key_id, var.kms_key_arn)

  # Backup and maintenance
  automated_snapshot_retention_period = each.value.automated_snapshot_retention_period
  preferred_maintenance_window        = each.value.preferred_maintenance_window

  # Snapshots
  snapshot_identifier       = each.value.snapshot_identifier
  final_snapshot_identifier = each.value.skip_final_snapshot ? null : coalesce(each.value.final_snapshot_identifier, "${each.key}-final-snapshot")
  skip_final_snapshot       = each.value.skip_final_snapshot

  # IAM roles
  iam_roles = local.cluster_iam_role_arns[each.key]

  # Advanced features
  aqua_configuration_status = each.value.aqua_configuration_status
  multi_az                  = each.value.multi_az

  # Logging
  dynamic "logging" {
    for_each = each.value.logging_enabled ? [1] : []
    content {
      enable               = true
      bucket_name          = each.value.log_destination_type == "s3" ? each.value.logging_bucket_name : null
      s3_key_prefix        = each.value.log_destination_type == "s3" ? each.value.logging_s3_key_prefix : null
      log_destination_type = each.value.log_destination_type
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })
}
