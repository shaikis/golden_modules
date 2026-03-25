# ── Code Signing Config ───────────────────────────────────────────────────────
resource "aws_lambda_code_signing_config" "this" {
  count = length(var.allowed_publishers_signing_profile_arns) > 0 ? 1 : 0

  description = "${local.name} code signing config"

  allowed_publishers {
    signing_profile_version_arns = var.allowed_publishers_signing_profile_arns
  }

  policies {
    untrusted_artifact_on_deployment = var.signing_untrusted_artifact_on_deployment
  }
}

# ── Lambda Layers (create new) ────────────────────────────────────────────────
resource "aws_lambda_layer_version" "this" {
  for_each = var.lambda_layers

  layer_name               = "${local.name}-${each.key}"
  description              = each.value.description
  filename                 = each.value.filename
  s3_bucket                = each.value.s3_bucket
  s3_key                   = each.value.s3_key
  s3_object_version        = each.value.s3_object_version
  compatible_runtimes      = each.value.compatible_runtimes
  compatible_architectures = each.value.compatible_architectures
  license_info             = each.value.license_info
  source_code_hash         = each.value.source_code_hash

  lifecycle {
    create_before_destroy = true
  }
}
