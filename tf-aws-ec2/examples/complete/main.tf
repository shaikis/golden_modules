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

module "ec2_fleet" {
  source = "git::https://github.com/shaikis/golden_modules.git//tf-aws-ec2?ref=main"

  name_prefix = "app"
  environment = "dev"
  project     = "payments"
  owner       = "cloud-team"
  cost_center = "12345"

  instances = {
    app01 = {
      instance_type          = "t3.medium"
      subnet_id              = "subnet-aaaa1111"
      vpc_security_group_ids = ["sg-aaaa1111"]
      create_eip             = true

      ebs_volumes = {
        data01 = {
          device_name = "/dev/sdf"
          volume_size = 100
          volume_type = "gp3"
          iops        = 3000
          throughput  = 125
        }
        data02 = {
          device_name = "/dev/sdg"
          volume_size = 200
          volume_type = "gp3"
          iops        = 3000
          throughput  = 125
        }
      }

      tags = {
        Role = "app"
      }
    }

    spot01 = {
      use_spot               = true
      spot_price             = "0.08"
      instance_type          = "t3.large"
      subnet_id              = "subnet-bbbb2222"
      vpc_security_group_ids = ["sg-bbbb2222"]

      ebs_volumes = {
        data01 = {
          device_name = "/dev/sdf"
          volume_size = 150
        }
      }

      tags = {
        Role = "worker"
      }
    }

    spot02 = {
      use_spot               = true
      spot_price             = "0.08"
      instance_type          = "t3.large"
      subnet_id              = "subnet-bbbb2222"
      vpc_security_group_ids = ["sg-bbbb2222"]

      tags = {
        Role = "worker"
      }
    }
  }
}

