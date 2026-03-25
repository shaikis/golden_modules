# ---------------------------------------------------------------------------
# EC2 Instance
# ---------------------------------------------------------------------------
resource "aws_instance" "this" {
  ami                                  = local.ami_id
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = var.vpc_security_group_ids
  iam_instance_profile                 = var.iam_instance_profile
  associate_public_ip_address          = var.associate_public_ip_address
  private_ip                           = var.private_ip
  secondary_private_ips                = var.secondary_private_ips
  availability_zone                    = var.availability_zone
  tenancy                              = var.tenancy
  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  monitoring                           = var.monitoring
  source_dest_check                    = var.source_dest_check
  get_password_data                    = var.get_password_data
  placement_group                      = var.placement_group
  user_data                            = var.user_data
  user_data_base64                     = var.user_data_base64
  user_data_replace_on_change          = var.user_data_replace_on_change

  # IMDSv2 required (security hardening)
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  # Root volume — encrypted by default
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    delete_on_termination = var.root_volume_delete_on_termination
    tags                  = merge(local.tags, { Name = "${local.name}-root" })
  }

  # Additional EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
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
      tags                  = merge(local.tags, { Name = "${local.name}-${ebs_block_device.key}" })
    }
  }

  dynamic "credit_specification" {
    for_each = var.cpu_credits != null ? [var.cpu_credits] : []
    content {
      cpu_credits = credit_specification.value
    }
  }

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []
    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  tags = local.tags

  lifecycle {
    # Prevent accidental termination via Terraform
    prevent_destroy = true
    # Ignore AMI changes — update via new launch or packer pipeline
    ignore_changes = [ami, user_data, tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Spot Instance Request (alternative to on-demand)
# ---------------------------------------------------------------------------
resource "aws_spot_instance_request" "this" {
  count = var.use_spot ? 1 : 0

  ami                         = local.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = var.associate_public_ip_address
  monitoring                  = var.monitoring
  spot_price                  = var.spot_price
  wait_for_fulfillment        = true

  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
  }

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = var.root_volume_encrypted
    kms_key_id  = var.root_volume_kms_key_id
    tags        = merge(local.tags, { Name = "${local.name}-root-spot" })
  }

  tags = merge(local.tags, { SpotInstance = "true" })
}
