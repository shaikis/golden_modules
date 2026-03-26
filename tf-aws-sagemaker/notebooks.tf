resource "aws_sagemaker_notebook_instance" "this" {
  for_each = var.create_notebooks ? var.notebooks : {}

  name          = "${local.name_prefix}${each.key}"
  role_arn      = local.role_arn
  instance_type = each.value.instance_type

  platform_identifier = each.value.platform_identifier
  volume_size         = each.value.volume_size_in_gb
  subnet_id           = each.value.subnet_id
  security_groups     = each.value.security_groups
  kms_key_id          = var.kms_key_arn

  tags = merge(local.tags, each.value.tags)
}
