locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-ec2"
  }
  tags = merge(local.default_tags, var.tags)

  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux[0].id
}
