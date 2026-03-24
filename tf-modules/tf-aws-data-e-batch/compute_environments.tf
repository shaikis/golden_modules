###############################################################################
# AWS Batch Compute Environments
###############################################################################

locals {
  batch_service_role_arn   = var.create_iam_role ? aws_iam_role.batch_service[0].arn : var.role_arn
  ec2_instance_profile_arn = var.create_iam_role ? aws_iam_instance_profile.batch_ec2[0].arn : null
  spot_fleet_role_arn      = var.create_iam_role ? aws_iam_role.spot_fleet[0].arn : null

  # Determine which compute environments need EC2/Spot-specific settings
  ec2_based_types = ["EC2", "SPOT"]
  fargate_types   = ["FARGATE", "FARGATE_SPOT"]
}

resource "aws_batch_compute_environment" "this" {
  for_each = var.compute_environments

  compute_environment_name = each.key
  type                     = each.value.type
  state                    = each.value.state
  service_role             = each.value.type == "MANAGED" ? local.batch_service_role_arn : null

  dynamic "compute_resources" {
    for_each = each.value.type == "MANAGED" ? [1] : []
    content {
      type      = each.value.compute_type
      max_vcpus = each.value.max_vcpus

      # min/desired only for EC2-type environments
      min_vcpus     = contains(local.ec2_based_types, each.value.compute_type) ? each.value.min_vcpus : null
      desired_vcpus = contains(local.ec2_based_types, each.value.compute_type) ? each.value.desired_vcpus : null

      subnets            = each.value.subnet_ids
      security_group_ids = each.value.security_group_ids

      # EC2/Spot specific
      instance_type = contains(local.ec2_based_types, each.value.compute_type) ? each.value.instance_types : null
      instance_role = contains(local.ec2_based_types, each.value.compute_type) ? local.ec2_instance_profile_arn : null

      bid_percentage      = each.value.compute_type == "SPOT" ? each.value.spot_bid_percentage : null
      spot_iam_fleet_role = each.value.compute_type == "SPOT" ? local.spot_fleet_role_arn : null

      allocation_strategy = contains(local.ec2_based_types, each.value.compute_type) ? each.value.allocation_strategy : null

      ec2_key_pair    = contains(local.ec2_based_types, each.value.compute_type) ? each.value.ec2_key_pair : null
      placement_group = contains(local.ec2_based_types, each.value.compute_type) ? each.value.placement_group : null

      dynamic "launch_template" {
        for_each = each.value.launch_template_id != null && contains(local.ec2_based_types, each.value.compute_type) ? [1] : []
        content {
          launch_template_id = each.value.launch_template_id
          version            = each.value.launch_template_version
        }
      }

      tags = merge(var.tags, each.value.instance_tags, {
        ComputeEnvironment = each.key
      })
    }
  }

  dynamic "eks_configuration" {
    for_each = each.value.eks_cluster_arn != null ? [1] : []
    content {
      eks_cluster_arn      = each.value.eks_cluster_arn
      kubernetes_namespace = each.value.kubernetes_namespace
    }
  }

  dynamic "update_policy" {
    for_each = each.value.type == "MANAGED" ? [1] : []
    content {
      terminate_jobs_on_update      = each.value.terminate_on_update
      job_execution_timeout_minutes = each.value.update_timeout_minutes
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}
