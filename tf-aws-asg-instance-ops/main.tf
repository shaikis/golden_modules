# ===========================================================================
# SCALE-IN PROTECTION (per instance)
# Protects specific instances from being terminated during scale-in.
# Use when you want to "pin" an instance for maintenance without leaving the ASG.
# ===========================================================================
resource "aws_autoscaling_attachment" "scale_in_protection" {
  # Scale-in protection is managed via aws_autoscaling_group + instance protection
  # Terraform does not have a native per-instance scale-in protection resource;
  # use the aws CLI or SSM automation via null_resource below.
  count = 0 # placeholder — see null_resource below
}

# Per-instance scale-in protection via AWS CLI (Terraform-managed)
resource "null_resource" "protect_instances" {
  for_each = toset(var.protected_instance_ids)

  triggers = {
    instance_id = each.value
    asg_name    = var.asg_name
    protected   = "true"
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws autoscaling set-instance-protection \
        --instance-ids ${each.value} \
        --auto-scaling-group-name ${var.asg_name} \
        --protected-from-scale-in
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws autoscaling set-instance-protection \
        --instance-ids ${self.triggers.instance_id} \
        --auto-scaling-group-name ${self.triggers.asg_name} \
        --no-protected-from-scale-in
    EOT
  }
}

# ===========================================================================
# STANDBY
# Moves instances to Standby state: detached from LB + health checks,
# but still part of ASG. Use for patching, debugging, or maintenance.
# Re-activate by removing from standby_instance_ids and re-applying.
# ===========================================================================
resource "null_resource" "enter_standby" {
  for_each = toset(var.standby_instance_ids)

  triggers = {
    instance_id       = each.value
    asg_name          = var.asg_name
    decrement_desired = tostring(var.standby_should_decrement_desired)
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws autoscaling enter-standby \
        --instance-ids ${each.value} \
        --auto-scaling-group-name ${var.asg_name} \
        ${var.standby_should_decrement_desired ? "--should-decrement-desired-capacity" : "--no-should-decrement-desired-capacity"}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws autoscaling exit-standby \
        --instance-ids ${self.triggers.instance_id} \
        --auto-scaling-group-name ${self.triggers.asg_name}
    EOT
  }
}

# ===========================================================================
# DETACH
# Fully removes instances from the ASG (they remain running but unmanaged).
# Safe for: migrating instances, re-launching in different ASG.
# ===========================================================================
resource "null_resource" "detach_instances" {
  for_each = toset(var.detach_instance_ids)

  triggers = {
    instance_id       = each.value
    asg_name          = var.asg_name
    decrement_desired = tostring(var.detach_should_decrement_desired)
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws autoscaling detach-instances \
        --instance-ids ${each.value} \
        --auto-scaling-group-name ${var.asg_name} \
        ${var.detach_should_decrement_desired ? "--should-decrement-desired-capacity" : "--no-should-decrement-desired-capacity"}
    EOT
  }
}
