# ===========================================================================
# AMI LOOKUP (used when ami_id is not provided)
# ===========================================================================
data "aws_ami" "amazon_linux" {
  count       = var.ami_id == null && var.os_type == "linux" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ssm_parameter" "windows_ami" {
  count = var.ami_id == null && var.os_type == "windows" ? 1 : 0
  name  = var.windows_ami_pattern
}

locals {
  resolved_ami = coalesce(
    var.ami_id,
    try(data.aws_ami.amazon_linux[0].id, null),
    try(data.aws_ssm_parameter.windows_ami[0].value, null)
  )

  user_data_final = local.is_windows ? local.windows_userdata : local.linux_userdata
}

# ===========================================================================
# LAUNCH TEMPLATE
# ===========================================================================
resource "aws_launch_template" "this" {
  name_prefix            = "${local.name}-lt-"
  image_id               = local.resolved_ami
  instance_type          = var.use_mixed_instances_policy ? null : var.instance_type
  key_name               = var.key_name
  ebs_optimized          = var.ebs_optimized
  update_default_version = true

  user_data = local.user_data_final

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  # IMDSv2 — mandatory
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    instance_metadata_tags      = "enabled"
  }

  # Root volume
  block_device_mappings {
    device_name = local.is_windows ? "/dev/sda1" : "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      iops                  = var.root_volume_iops
      throughput            = var.root_volume_throughput
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  # Additional EBS volumes
  dynamic "block_device_mappings" {
    for_each = var.extra_ebs_volumes
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        iops                  = block_device_mappings.value.iops
        throughput            = block_device_mappings.value.throughput
        encrypted             = block_device_mappings.value.encrypted
        kms_key_id            = var.kms_key_arn
        delete_on_termination = true
      }
    }
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = var.security_group_ids
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      OSType  = var.os_type
      ASGName = local.name
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags, {
      OSType  = var.os_type
      ASGName = local.name
    })
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = local.tags
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
    # When ANY launch template attribute changes, Terraform creates a new
    # version (name_prefix + create_before_destroy). The ASG uses $Latest
    # so new instances automatically get the latest version.
    # Existing instances are rolled by instance_refresh (configured on ASG).
  }
}

# ===========================================================================
# AUTO SCALING GROUP
# ===========================================================================
resource "aws_autoscaling_group" "this" {
  name                      = local.name
  vpc_zone_identifier       = var.vpc_zone_identifier
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  # target_group_arns is intentionally NOT set here.
  # Attachments are managed via aws_autoscaling_attachment below,
  # so adding or removing a TG ARN from var.target_group_arns always works.
  termination_policies             = var.termination_policies
  protect_from_scale_in            = var.protect_from_scale_in
  capacity_rebalance               = var.capacity_rebalance
  suspended_processes              = length(var.suspended_processes) > 0 ? var.suspended_processes : null
  max_instance_lifetime            = var.max_instance_lifetime
  default_instance_warmup          = var.default_instance_warmup
  wait_for_capacity_timeout        = var.wait_for_capacity_timeout
  force_delete                     = var.force_delete
  ignore_failed_scaling_activities = var.ignore_failed_scaling_activities

  # Mixed instances policy (Spot + On-Demand)
  dynamic "mixed_instances_policy" {
    for_each = var.use_mixed_instances_policy ? [1] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this.id
          version            = aws_launch_template.this.latest_version
        }
        dynamic "override" {
          for_each = var.override_instance_types
          content {
            instance_type = override.value
          }
        }
      }
      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base
        spot_allocation_strategy                 = var.spot_allocation_strategy
      }
    }
  }

  # Standard launch template (non-mixed)
  # IMPORTANT: version = "$Latest" ensures new instances always use the latest
  # launch template version. Existing running instances are updated by
  # instance_refresh (rolling update) — which fires automatically on re-apply
  # when the launch template latest_version number changes.
  dynamic "launch_template" {
    for_each = var.use_mixed_instances_policy ? [] : [1]
    content {
      id      = aws_launch_template.this.id
      version = aws_launch_template.this.latest_version # explicit version → triggers instance_refresh
    }
  }

  # Rolling instance refresh — fires automatically when launch_template.version
  # changes (i.e. every time the launch template is updated).
  dynamic "instance_refresh" {
    for_each = var.instance_refresh_strategy != null ? [1] : []
    content {
      strategy = var.instance_refresh_strategy
      triggers = ["launch_template"] # explicit trigger on LT change
      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
        checkpoint_percentages = var.instance_refresh_checkpoint_percentages
      }
    }
  }

  # Tag instances (Name will be overwritten by userdata with unique hostname)
  dynamic "tag" {
    for_each = merge(local.tags, {
      OSType  = var.os_type
      ASGName = local.name
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Warm pool (pre-warmed standby instances)
  dynamic "warm_pool" {
    for_each = var.warm_pool != null ? [var.warm_pool] : []
    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                    = warm_pool.value.min_size
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity
      instance_reuse_policy {
        reuse_on_scale_in = warm_pool.value.reuse_on_scale_in
      }
    }
  }

  lifecycle {
    # desired_capacity: managed by scaling policies at runtime — don't fight them.
    # load_balancers:   classic ELB attachments managed outside Terraform.
    # target_group_arns NOT ignored — managed via aws_autoscaling_attachment below.
    ignore_changes = [desired_capacity, load_balancers]
  }
}

# ===========================================================================
# TARGET GROUP ATTACHMENTS
# One aws_autoscaling_attachment per TG ARN in var.target_group_arns.
# Using separate attachment resources (not the inline target_group_arns
# attribute on the ASG) means you can add or remove TGs at any time by
# updating var.target_group_arns and running terraform apply — works both ways.
# ===========================================================================
resource "aws_autoscaling_attachment" "this" {
  for_each = toset(var.target_group_arns)

  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = each.value
}

# ===========================================================================
# LIFECYCLE HOOKS
# ===========================================================================
resource "aws_autoscaling_lifecycle_hook" "this" {
  for_each = var.lifecycle_hooks

  name                    = "${local.name}-${each.key}"
  autoscaling_group_name  = aws_autoscaling_group.this.name
  lifecycle_transition    = each.value.lifecycle_transition
  heartbeat_timeout       = each.value.heartbeat_timeout
  default_result          = each.value.default_result
  notification_target_arn = each.value.notification_target_arn
  role_arn                = each.value.role_arn
}

# ===========================================================================
# SCALING POLICIES
# ===========================================================================

# CPU-based target tracking
resource "aws_autoscaling_policy" "cpu" {
  count = var.enable_cpu_scaling ? 1 : 0

  name                      = "${local.name}-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.default_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# Memory-based target tracking (requires CW agent)
resource "aws_autoscaling_policy" "memory" {
  count = var.enable_memory_scaling ? 1 : 0

  name                      = "${local.name}-memory-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.default_instance_warmup

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "MemoryUtilization"
      namespace   = "CWAgent"
      statistic   = "Average"
      metric_dimension {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.this.name
      }
    }
    target_value = var.memory_target_value
  }
}

# ALB request count per target
resource "aws_autoscaling_policy" "alb_request" {
  count = var.enable_alb_request_scaling && var.alb_target_group_arn_suffix != null ? 1 : 0

  name                      = "${local.name}-alb-request-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.default_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${var.alb_target_group_arn_suffix}"
    }
    target_value = var.alb_request_target_value
  }
}

# Network IN
resource "aws_autoscaling_policy" "network_in" {
  count = var.enable_network_in_scaling ? 1 : 0

  name                      = "${local.name}-network-in-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.default_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkIn"
    }
    target_value = var.network_in_target_bytes
  }
}

# Network OUT
resource "aws_autoscaling_policy" "network_out" {
  count = var.enable_network_out_scaling ? 1 : 0

  name                      = "${local.name}-network-out-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.default_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageNetworkOut"
    }
    target_value = var.network_out_target_bytes
  }
}

# SQS-based custom metric target tracking
resource "aws_autoscaling_policy" "sqs" {
  count = var.enable_sqs_scaling && var.sqs_queue_name != null ? 1 : 0

  name                      = "${local.name}-sqs-target"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.default_instance_warmup

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Sum"
      metric_dimension {
        name  = "QueueName"
        value = var.sqs_queue_name
      }
    }
    target_value = var.sqs_messages_per_instance
  }
}

# Step scaling policies with CloudWatch alarms
resource "aws_autoscaling_policy" "step" {
  for_each = var.step_scaling_policies

  name                      = "${local.name}-${each.key}"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "StepScaling"
  adjustment_type           = each.value.adjustment_type
  metric_aggregation_type   = each.value.metric_aggregation_type
  estimated_instance_warmup = var.health_check_grace_period

  dynamic "step_adjustment" {
    for_each = each.value.step_adjustments
    content {
      metric_interval_lower_bound = step_adjustment.value.lower_bound
      metric_interval_upper_bound = step_adjustment.value.upper_bound
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
    }
  }
}

# CloudWatch alarms for step scaling
resource "aws_cloudwatch_metric_alarm" "step" {
  for_each = var.step_scaling_policies

  alarm_name          = "${local.name}-${each.key}-alarm"
  metric_name         = each.value.alarm_metric_name
  namespace           = each.value.alarm_namespace
  statistic           = each.value.alarm_statistic
  period              = each.value.alarm_period
  evaluation_periods  = each.value.alarm_evaluation_periods
  threshold           = each.value.alarm_threshold
  comparison_operator = each.value.alarm_comparison_operator

  dimensions = merge({ AutoScalingGroupName = aws_autoscaling_group.this.name }, each.value.alarm_dimensions)

  alarm_actions = [aws_autoscaling_policy.step[each.key].arn]
  tags          = local.tags
}

# ===========================================================================
# SCHEDULED ACTIONS
# ===========================================================================
resource "aws_autoscaling_schedule" "this" {
  for_each = var.scheduled_actions

  scheduled_action_name  = "${local.name}-${each.key}"
  autoscaling_group_name = aws_autoscaling_group.this.name
  recurrence             = each.value.recurrence
  start_time             = each.value.start_time
  end_time               = each.value.end_time
  min_size               = each.value.min_size
  max_size               = each.value.max_size
  desired_capacity       = each.value.desired_capacity
  time_zone              = each.value.time_zone
}
