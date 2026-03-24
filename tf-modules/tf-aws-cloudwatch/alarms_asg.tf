# =============================================================================
# tf-aws-cloudwatch — Auto Scaling Group (ASG) Alarms
#
# Creates alarms for each ASG:
#   1. CPU High  → instances may be overwhelmed; scale-out may be slow or stuck
#   2. CPU Low   → over-provisioned; scale-in will reduce cost but verify first
#   3. Maxed Out → at maximum capacity; cannot scale further, traffic may be dropped
#   4. Below Min → fewer instances than expected; instance failures or launch errors
#
# To disable: set asg_alarms = {}
# =============================================================================

# ── Variables ─────────────────────────────────────────────────────────────────

variable "asg_alarms" {
  description = <<-EOT
    Map of Auto Scaling Group alarm configurations.
    Key = ASG name (exact name as it appears in the AWS console / EC2 ASG list).

    Example:
      "prod-myapp-asg" = {
        cpu_high_threshold = 75
        cpu_low_threshold  = 15
        min_group_size     = 2
        max_group_size     = 10
      }
  EOT
  type = map(object({
    # Scale-up pressure (investigate if CPU stays high after scale-out)
    cpu_high_threshold          = optional(number, 80)
    cpu_high_evaluation_periods = optional(number, 2)
    cpu_high_period             = optional(number, 300)

    # Scale-down signal (ASG is over-provisioned — cost optimization)
    cpu_low_threshold          = optional(number, 20)
    cpu_low_evaluation_periods = optional(number, 3)
    cpu_low_period             = optional(number, 300)

    # Group size alarms (optional — set to match your ASG min/max config)
    min_group_size = optional(number, null) # alarm when InService instances < this
    max_group_size = optional(number, null) # alarm when InService instances >= this
  }))
  default = {}
}

# ── CPU High Alarm ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  for_each = var.asg_alarms

  alarm_name          = "${local.prefix}-asg-${each.key}-cpu-high"
  alarm_description   = "ASG ${each.key}: CPU above ${each.value.cpu_high_threshold}%. Scale-out may be needed or a runaway process is present."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.cpu_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = each.value.cpu_high_period
  statistic           = "Average"
  threshold           = each.value.cpu_high_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = each.key
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "asg" })
}

# ── CPU Low Alarm ─────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "asg_cpu_low" {
  for_each = var.asg_alarms

  alarm_name          = "${local.prefix}-asg-${each.key}-cpu-low"
  alarm_description   = "ASG ${each.key}: CPU below ${each.value.cpu_low_threshold}% for extended period. ASG may be over-provisioned — review desired capacity."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = each.value.cpu_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = each.value.cpu_low_period
  statistic           = "Average"
  threshold           = each.value.cpu_low_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = each.key
  }

  alarm_actions = local.default_alarm_actions
  ok_actions    = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "warning", Component = "asg" })
}

# ── Maxed Out Alarm ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "asg_maxed_out" {
  for_each = { for k, v in var.asg_alarms : k => v if v.max_group_size != null }

  alarm_name          = "${local.prefix}-asg-${each.key}-maxed-out"
  alarm_description   = "ASG ${each.key} is at maximum capacity (${each.value.max_group_size} instances). Cannot scale out further — requests may be rejected."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Maximum"
  threshold           = each.value.max_group_size
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = each.key
  }

  alarm_actions = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "asg" })
}

# ── Below Minimum Alarm ───────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "asg_below_min" {
  for_each = { for k, v in var.asg_alarms : k => v if v.min_group_size != null }

  alarm_name          = "${local.prefix}-asg-${each.key}-below-minimum"
  alarm_description   = "ASG ${each.key} has fewer than ${each.value.min_group_size} healthy instances. Possible instance health-check failures or launch errors."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Minimum"
  threshold           = each.value.min_group_size
  treat_missing_data  = "breaching"

  dimensions = {
    AutoScalingGroupName = each.key
  }

  alarm_actions = local.default_alarm_actions

  tags = merge(local.common_tags, { Severity = "critical", Component = "asg" })
}
