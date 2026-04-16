locals {
  instance_names = {
    for k, v in var.instances :
    k => (
      try(v.name, null) != null && try(v.name, "") != ""
      ? (var.name_prefix != "" ? "${var.name_prefix}-${v.name}" : v.name)
      : (var.name_prefix != "" ? "${var.name_prefix}-${k}" : k)
    )
  }

  default_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-ec2"
  }

  instance_tags = {
    for k, v in var.instances :
    k => merge(
      local.default_tags,
      var.tags,
      try(v.tags, {}),
      { Name = local.instance_names[k] }
    )
  }

  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux[0].id

  normalized_instances = {
    for k, v in var.instances :
    k => merge(v, {
      ebs_volumes = {
        for vol_name, vol in try(v.ebs_volumes, {}) :
        vol_name => merge(vol, {
          kms_key_id = try(vol.kms_key_id, null) != null ? vol.kms_key_id : try(v.root_volume_kms_key_id, null)
        })
      }
    })
  }

  ondemand_instances = {
    for k, v in local.normalized_instances : k => v
    if !try(v.use_spot, false)
  }

  spot_instances = {
    for k, v in local.normalized_instances : k => v
    if try(v.use_spot, false)
  }

  eip_instances = {
    for k, v in local.ondemand_instances : k => v
    if try(v.create_eip, false)
  }
}
