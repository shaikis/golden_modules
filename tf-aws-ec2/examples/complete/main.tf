provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = "${var.name}-ebs"
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  description                       = "EBS encryption key for ${var.name}"
  key_usage                         = "ENCRYPT_DECRYPT"
  customer_master_key_spec          = "SYMMETRIC_DEFAULT"
  enable_key_rotation               = true
  deletion_window_in_days           = 30
  is_enabled                        = true
  multi_region                      = false
  key_administrators                = []
  key_users                         = []
  key_service_roles_for_autoscaling = []
  policy                            = ""
  enable_default_policy             = true
  aliases                           = []
  grants                            = {}
}

module "role" {
  source      = "../../../tf-aws-iam-role"
  name        = "${var.name}-role"
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  description             = "EC2 instance role for ${var.name}"
  max_session_duration    = 3600
  force_detach_policies   = true
  permissions_boundary    = null
  trusted_role_arns       = []
  trusted_role_services   = ["ec2.amazonaws.com"]
  trusted_role_actions    = ["sts:AssumeRole"]
  assume_role_conditions  = []
  custom_trust_policy     = ""
  managed_policy_arns     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  inline_policies         = {}
  create_instance_profile = true
}

module "sg" {
  source      = "../../../tf-aws-security-group"
  name        = "${var.name}-sg"
  name_prefix = var.name_prefix
  description = "Security group for ${var.name} EC2 instances"
  vpc_id      = var.vpc_id
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  ingress_rules = {
    ssh_from_vpn = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal network"
    }
  }
  egress_rules = {
    all_outbound = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  }
  revoke_rules_on_delete = true
}

module "ec2" {
  source      = "../../"
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id
  key_name          = var.key_name
  availability_zone = var.availability_zone
  tenancy           = var.tenancy
  placement_group   = var.placement_group

  vpc_security_group_ids      = [module.sg.security_group_id]
  iam_instance_profile        = module.role.instance_profile_name
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  secondary_private_ips       = var.secondary_private_ips
  source_dest_check           = var.source_dest_check

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  monitoring                           = var.monitoring
  get_password_data                    = var.get_password_data

  root_volume_type                  = var.root_volume_type
  root_volume_size                  = var.root_volume_size
  root_volume_iops                  = var.root_volume_iops
  root_volume_throughput            = var.root_volume_throughput
  root_volume_encrypted             = var.root_volume_encrypted
  root_volume_kms_key_id            = module.kms.key_arn
  root_volume_delete_on_termination = var.root_volume_delete_on_termination

  ebs_volumes      = var.ebs_volumes
  cpu_options      = var.cpu_options
  cpu_credits      = var.cpu_credits
  metadata_options = var.metadata_options

  create_eip = var.create_eip
  use_spot   = var.use_spot
  spot_price = var.spot_price
}
