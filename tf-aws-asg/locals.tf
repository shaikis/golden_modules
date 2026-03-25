locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-asg"
    },
    var.tags
  )

  is_windows = var.os_type == "windows"

  # Unique hostname prefix for each ASG instance
  # Linux  → <name>-linux-<random>   (via user_data)
  # Windows → <name>-win-<random>    (via PowerShell userdata / SSM)
  hostname_prefix = local.is_windows ? "${local.name}-win" : "${local.name}-lx"

  # Linux user_data: set unique hostname at boot, install SSM agent if needed
  linux_userdata = var.user_data != "" ? var.user_data : base64encode(templatefile("${path.module}/templates/linux_userdata.sh.tpl", {
    hostname_prefix = local.hostname_prefix
    extra_commands  = var.extra_user_data_commands
  }))

  # Windows user_data: PowerShell rename + join domain if configured
  windows_userdata = var.user_data != "" ? var.user_data : base64encode(templatefile("${path.module}/templates/windows_userdata.ps1.tpl", {
    hostname_prefix    = local.hostname_prefix
    domain_name        = var.windows_domain_name
    domain_join_secret = var.windows_domain_join_secret_arn
    extra_commands     = var.extra_user_data_commands
  }))
}
