resource "aws_dms_replication_subnet_group" "this" {
  for_each = var.subnet_groups

  replication_subnet_group_description = each.value.description
  replication_subnet_group_id          = each.key
  subnet_ids                           = each.value.subnet_ids

  tags = merge(var.tags, each.value.tags)

  depends_on = [aws_iam_role.dms_vpc_role]
}

resource "aws_dms_replication_instance" "this" {
  for_each = var.replication_instances

  replication_instance_id      = each.key
  replication_instance_class   = each.value.replication_instance_class
  allocated_storage            = each.value.allocated_storage
  multi_az                     = each.value.multi_az
  engine_version               = each.value.engine_version
  auto_minor_version_upgrade   = each.value.auto_minor_version_upgrade
  publicly_accessible          = each.value.publicly_accessible
  vpc_security_group_ids       = each.value.vpc_security_group_ids
  replication_subnet_group_id  = each.value.replication_subnet_group_id
  kms_key_arn                  = coalesce(each.value.kms_key_arn, var.kms_key_arn)
  preferred_maintenance_window = each.value.preferred_maintenance_window
  apply_immediately            = each.value.apply_immediately
  allow_major_version_upgrade  = each.value.allow_major_version_upgrade

  tags = merge(var.tags, each.value.tags)

  depends_on = [aws_iam_role.dms_vpc_role]
}
