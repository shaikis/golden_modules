locals {
  name                     = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  hostname_product_acronym = trimspace(var.product_acronym) != "" ? var.product_acronym : (trimspace(var.project) != "" ? var.project : var.name)

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
  region_code_map = {
    "us-east-1"      = "use1"
    "us-east-2"      = "use2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-central-1"   = "euce1"
    "eu-central-2"   = "euce2"
    "ap-south-1"     = "aps1"
    "ap-south-2"     = "aps2"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ca-central-1"   = "cace1"
    "sa-east-1"      = "sae1"
  }
  region_code = lookup(local.region_code_map, data.aws_region.current.region, replace(data.aws_region.current.region, "/-/", ""))

  linux_hostname_seed    = replace(lower("${local.hostname_product_acronym}${var.name}${var.environment}"), "/[^0-9a-z]/", "")
  linux_hostname_compact = local.linux_hostname_seed
  linux_hostname_trimmed = local.linux_hostname_compact
  linux_hostname_prefix  = substr(local.linux_hostname_trimmed != "" ? local.linux_hostname_trimmed : "asg", 0, 54)
  windows_product_code   = substr(replace(upper(local.hostname_product_acronym), "/[^0-9A-Z]/", ""), 0, 4)
  windows_region_code    = substr(upper(local.region_code), 0, 5)
  windows_purpose_code   = substr(replace(upper(var.name), "/[^0-9A-Z]/", ""), 0, 4)
  windows_env_code       = substr(replace(upper(var.environment), "/[^0-9A-Z]/", ""), 0, 2)
  windows_hostname_prefix = var.windows_hostname_strategy == "product_region_octet" ? (
    "${local.windows_product_code != "" ? local.windows_product_code : "APP"}-${local.windows_region_code}"
    ) : (
    "${local.windows_product_code != "" ? local.windows_product_code : "APP"}${local.windows_purpose_code}${local.windows_env_code}"
  )
  hostname_prefix          = local.is_windows ? local.windows_hostname_prefix : local.linux_hostname_prefix
  hostname_separator       = ""
  additional_user_commands = var.user_data != "" ? textdecodebase64(var.user_data) : var.extra_user_data_commands

  bootstrap_enabled          = var.bootstrap != null && try(var.bootstrap.enabled, true)
  bootstrap_entrypoint_linux = local.bootstrap_enabled ? try(var.bootstrap.entrypoint.linux, "/opt/bootstrap/bootstrap.sh") : ""
  bootstrap_entrypoint_win   = local.bootstrap_enabled ? try(var.bootstrap.entrypoint.windows, "C:\\Bootstrap\\bootstrap.ps1") : ""
  bootstrap_s3_bucket        = local.bootstrap_enabled ? try(var.bootstrap.s3.bucket, "") : ""
  bootstrap_s3_key_prefix    = local.bootstrap_enabled ? try(var.bootstrap.s3.key_prefix, "") : ""
  bootstrap_s3_manifest_key  = local.bootstrap_enabled ? try(var.bootstrap.s3.manifest_key, "") : ""
  bootstrap_context_json = jsonencode({
    features = {
      cloudwatch_agent = local.bootstrap_enabled ? try(var.bootstrap.features.cloudwatch_agent, false) : false
      dynatrace        = local.bootstrap_enabled ? try(var.bootstrap.features.dynatrace, false) : false
      grafana_alloy    = local.bootstrap_enabled ? try(var.bootstrap.features.grafana_alloy, false) : false
      ansible_winrm    = local.bootstrap_enabled ? try(var.bootstrap.features.ansible_winrm, false) : false
    }
    secrets = {
      dynatrace_token_secret_arn = local.bootstrap_enabled ? try(var.bootstrap.secrets.dynatrace_token_secret_arn, null) : null
      grafana_secret_arn         = local.bootstrap_enabled ? try(var.bootstrap.secrets.grafana_secret_arn, null) : null
      ansible_winrm_secret_arn   = local.bootstrap_enabled ? try(var.bootstrap.secrets.ansible_winrm_secret_arn, null) : null
    }
    parameters = local.bootstrap_enabled ? try(var.bootstrap.parameters, {}) : {}
    s3 = {
      bucket       = local.bootstrap_s3_bucket
      key_prefix   = local.bootstrap_s3_key_prefix
      manifest_key = local.bootstrap_s3_manifest_key
    }
  })

  linux_userdata = base64encode(templatefile("${path.module}/templates/linux_userdata.sh.tpl", {
    hostname_prefix         = local.linux_hostname_prefix
    hostname_separator      = ""
    region_code             = local.region_code
    extra_commands          = local.additional_user_commands
    bootstrap_enabled       = local.bootstrap_enabled
    bootstrap_entrypoint    = local.bootstrap_entrypoint_linux
    bootstrap_s3_bucket     = local.bootstrap_s3_bucket
    bootstrap_s3_key_prefix = local.bootstrap_s3_key_prefix
    bootstrap_manifest_key  = local.bootstrap_s3_manifest_key
    bootstrap_context_json  = local.bootstrap_context_json
  }))

  windows_userdata = base64encode(templatefile("${path.module}/templates/windows_userdata.ps1.tpl", {
    hostname_prefix         = local.windows_hostname_prefix
    hostname_separator      = "-"
    domain_name             = var.windows_domain_name
    domain_join_secret      = var.windows_domain_join_secret_arn
    extra_commands          = local.additional_user_commands
    bootstrap_enabled       = local.bootstrap_enabled
    bootstrap_entrypoint    = local.bootstrap_entrypoint_win
    bootstrap_s3_bucket     = local.bootstrap_s3_bucket
    bootstrap_s3_key_prefix = local.bootstrap_s3_key_prefix
    bootstrap_manifest_key  = local.bootstrap_s3_manifest_key
    bootstrap_context_json  = local.bootstrap_context_json
  }))
}
