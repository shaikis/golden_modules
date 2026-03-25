# ===========================================================================
# IAM ROLES
# ===========================================================================
resource "aws_iam_role" "instance" {
  name = "${local.name}-image-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ec2_image_builder" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_logs" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.name}-image-builder-profile"
  role = aws_iam_role.instance.name
  tags = local.tags
}

# ===========================================================================
# CUSTOM COMPONENTS
# ===========================================================================
resource "aws_imagebuilder_component" "custom" {
  for_each = var.custom_components

  name        = "${local.name}-${each.key}"
  platform    = coalesce(each.value.platform, var.platform)
  version     = each.value.version
  description = each.value.description
  data        = each.value.data

  kms_key_id = var.kms_key_arn

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================================================
# IMAGE RECIPE
# ===========================================================================
locals {
  # Resolve parent image
  resolved_parent_image = coalesce(
    var.parent_image,
    local.is_windows ? var.windows_parent_image_ssm : var.linux_parent_image_ssm
  )

  # Software option components (inline)
  sw_cwa_data = var.install_cloudwatch_agent ? (local.is_windows ? file("${path.module}/components/windows/cloudwatch_agent.yml") : file("${path.module}/components/linux/cloudwatch_agent.yml")) : null
  sw_dt_data  = var.install_dynatrace        ? (local.is_windows ? file("${path.module}/components/windows/dynatrace.yml")         : file("${path.module}/components/linux/dynatrace.yml"))         : null
  sw_ora_data = var.install_oracle_client    ? (local.is_windows ? file("${path.module}/components/windows/oracle_client.yml")     : file("${path.module}/components/linux/oracle_client.yml"))     : null
  sw_iis_data = var.install_iis && local.is_windows ? file("${path.module}/components/windows/iis.yml")                                                                                                : null
  sw_grf_data = var.install_grafana_agent    ? (local.is_windows ? null                                                            : file("${path.module}/components/linux/grafana_agent.yml"))     : null

  software_components_raw = {
    for k, v in {
      cwa      = { data = local.sw_cwa_data; params = [{ name = "CWAgentConfigSsmParam"; value = [var.cloudwatch_agent_ssm_param] }] }
      dynatrace = { data = local.sw_dt_data;  params = [{ name = "DynatraceEnvUrl"; value = [var.dynatrace_env_url] }, { name = "DynatraceApiToken"; value = [var.dynatrace_api_token] }] }
      oracle    = { data = local.sw_ora_data; params = [{ name = "OracleClientVersion"; value = [var.oracle_client_version] }, { name = "OracleClientS3Bucket"; value = [var.oracle_client_s3_bucket] }] }
      iis       = { data = local.sw_iis_data; params = [{ name = "EnableAspNet48"; value = [tostring(var.iis_enable_aspnet48)] }] }
      grafana   = { data = local.sw_grf_data; params = [{ name = "GrafanaAgentVersion"; value = [var.grafana_agent_version] }] }
    } : k => v if v.data != null
  }

  # Merge custom + software-option + caller-provided components
  all_components = concat(
    [for k, v in aws_imagebuilder_component.custom : { component_arn = v.arn, parameters = [] }],
    [for k, v in aws_imagebuilder_component.software_options : { component_arn = v.arn, parameters = local.software_components_raw[k].params }],
    var.components
  )
}

resource "aws_imagebuilder_component" "software_options" {
  for_each = local.software_components_raw

  name     = "${local.name}-sw-${each.key}"
  platform = var.platform
  version  = var.recipe_version
  data     = each.value.data

  kms_key_id = var.kms_key_arn

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_imagebuilder_image_recipe" "this" {
  name         = local.name
  parent_image = local.resolved_parent_image
  version      = var.recipe_version

  dynamic "component" {
    for_each = local.all_components
    content {
      component_arn = component.value.component_arn
      dynamic "parameter" {
        for_each = component.value.parameters
        content {
          name  = parameter.value.name
          value = parameter.value.value
        }
      }
    }
  }

  block_device_mapping {
    device_name = local.is_windows ? "/dev/sda1" : "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================================================
# INFRASTRUCTURE CONFIGURATION
# ===========================================================================
resource "aws_imagebuilder_infrastructure_configuration" "this" {
  name                          = "${local.name}-infra"
  instance_types                = var.instance_types
  instance_profile_name         = aws_iam_instance_profile.instance.name
  subnet_id                     = var.subnet_id
  security_group_ids            = var.security_group_ids
  terminate_instance_on_failure = var.terminate_on_failure
  sns_topic_arn                 = var.sns_topic_arn

  tags = local.tags
}

# ===========================================================================
# DISTRIBUTION CONFIGURATION
# ===========================================================================
resource "aws_imagebuilder_distribution_configuration" "this" {
  name = "${local.name}-dist"

  # Primary region (always)
  distribution {
    region = data.aws_region.current.name
    ami_distribution_configuration {
      name               = "${coalesce(var.ami_name_prefix, local.name)}-{{ imagebuilder:buildDate }}"
      ami_tags           = local.tags
      target_account_ids = var.ami_launch_permissions
    }
  }

  # Additional regions
  dynamic "distribution" {
    for_each = var.distribution_regions
    content {
      region = distribution.value
      ami_distribution_configuration {
        name     = "${coalesce(var.ami_name_prefix, local.name)}-{{ imagebuilder:buildDate }}"
        ami_tags = local.tags
      }
    }
  }

  tags = local.tags
}

data "aws_region" "current" {}

# ===========================================================================
# IMAGE PIPELINE
# ===========================================================================
resource "aws_imagebuilder_image_pipeline" "this" {
  name                             = local.name
  image_recipe_arn                 = aws_imagebuilder_image_recipe.this.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.this.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.this.arn
  status                           = var.pipeline_enabled ? "ENABLED" : "DISABLED"

  dynamic "schedule" {
    for_each = var.pipeline_schedule_expression != null ? [1] : []
    content {
      schedule_expression                = var.pipeline_schedule_expression
      timezone                           = var.pipeline_timezone
      pipeline_execution_start_condition = "EXPRESSION_MATCH_ONLY"
    }
  }

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 90
  }

  tags = local.tags
}
