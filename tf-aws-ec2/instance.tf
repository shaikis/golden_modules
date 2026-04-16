resource "aws_instance" "this" {
  for_each = local.ondemand_instances

  ami                                  = local.ami_id
  instance_type                        = each.value.instance_type
  key_name                             = each.value.key_name
  subnet_id                            = each.value.subnet_id
  vpc_security_group_ids               = each.value.vpc_security_group_ids
  iam_instance_profile                 = each.value.iam_instance_profile
  associate_public_ip_address          = each.value.associate_public_ip_address
  private_ip                           = each.value.private_ip
  secondary_private_ips                = each.value.secondary_private_ips
  availability_zone                    = each.value.availability_zone
  tenancy                              = each.value.tenancy
  disable_api_termination              = each.value.disable_api_termination
  disable_api_stop                     = each.value.disable_api_stop
  instance_initiated_shutdown_behavior = each.value.instance_initiated_shutdown_behavior
  monitoring                           = each.value.monitoring
  source_dest_check                    = each.value.source_dest_check
  get_password_data                    = each.value.get_password_data
  placement_group                      = each.value.placement_group
  user_data                            = each.value.user_data
  user_data_base64                     = each.value.user_data_base64
  user_data_replace_on_change          = each.value.user_data_replace_on_change

  metadata_options {
    http_endpoint               = each.value.metadata_options.http_endpoint
    http_tokens                 = each.value.metadata_options.http_tokens
    http_put_response_hop_limit = each.value.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = each.value.metadata_options.instance_metadata_tags
  }

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = each.value.root_volume_iops
    throughput            = each.value.root_volume_throughput
    encrypted             = each.value.root_volume_encrypted
    kms_key_id            = each.value.root_volume_kms_key_id
    delete_on_termination = each.value.root_volume_delete_on_termination

    tags = merge(local.instance_tags[each.key], {
      Name = "${local.instance_names[each.key]}-root"
    })
  }

  dynamic "ebs_block_device" {
    for_each = each.value.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.iops
      throughput            = ebs_block_device.value.throughput
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.kms_key_id
      delete_on_termination = ebs_block_device.value.delete_on_termination
      snapshot_id           = ebs_block_device.value.snapshot_id

      tags = merge(local.instance_tags[each.key], {
        Name = "${local.instance_names[each.key]}-${ebs_block_device.key}"
      })
    }
  }

  dynamic "credit_specification" {
    for_each = each.value.cpu_credits != null ? [each.value.cpu_credits] : []
    content {
      cpu_credits = credit_specification.value
    }
  }

  dynamic "cpu_options" {
    for_each = each.value.cpu_options != null ? [each.value.cpu_options] : []
    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  tags = local.instance_tags[each.key]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ami, user_data, tags["CreatedDate"]]
  }
}

resource "aws_spot_instance_request" "this" {
  for_each = local.spot_instances

  ami                         = local.ami_id
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = each.value.vpc_security_group_ids
  iam_instance_profile        = each.value.iam_instance_profile
  associate_public_ip_address = each.value.associate_public_ip_address
  private_ip                  = each.value.private_ip
  secondary_private_ips       = each.value.secondary_private_ips
  availability_zone           = each.value.availability_zone
  monitoring                  = each.value.monitoring
  source_dest_check           = each.value.source_dest_check
  placement_group             = each.value.placement_group
  user_data                   = each.value.user_data
  user_data_base64            = each.value.user_data_base64

  spot_price           = each.value.spot_price
  wait_for_fulfillment = true

  metadata_options {
    http_endpoint               = each.value.metadata_options.http_endpoint
    http_tokens                 = each.value.metadata_options.http_tokens
    http_put_response_hop_limit = each.value.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = each.value.metadata_options.instance_metadata_tags
  }

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = each.value.root_volume_iops
    throughput            = each.value.root_volume_throughput
    encrypted             = each.value.root_volume_encrypted
    kms_key_id            = each.value.root_volume_kms_key_id
    delete_on_termination = each.value.root_volume_delete_on_termination

    tags = merge(local.instance_tags[each.key], {
      Name = "${local.instance_names[each.key]}-root"
    })
  }

  dynamic "ebs_block_device" {
    for_each = each.value.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.iops
      throughput            = ebs_block_device.value.throughput
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.kms_key_id
      delete_on_termination = ebs_block_device.value.delete_on_termination
      snapshot_id           = ebs_block_device.value.snapshot_id

      tags = merge(local.instance_tags[each.key], {
        Name = "${local.instance_names[each.key]}-${ebs_block_device.key}"
      })
    }
  }

  dynamic "credit_specification" {
    for_each = each.value.cpu_credits != null ? [each.value.cpu_credits] : []
    content {
      cpu_credits = credit_specification.value
    }
  }

  dynamic "cpu_options" {
    for_each = each.value.cpu_options != null ? [each.value.cpu_options] : []
    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  tags = merge(local.instance_tags[each.key], {
    SpotInstance = "true"
  })
}
