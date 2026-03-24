resource "aws_secretsmanager_secret" "this" {
  name                           = local.name
  description                    = var.description
  kms_key_id                     = var.kms_key_id
  recovery_window_in_days        = var.recovery_window_days
  force_overwrite_replica_secret = var.force_overwrite_replica_secret

  dynamic "replica" {
    for_each = var.replicas
    content {
      region     = replica.key
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  count         = var.secret_string != null || var.secret_binary != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
  secret_binary = var.secret_binary

  lifecycle {
    # Don't overwrite secret value on re-apply (managed externally)
    ignore_changes = [secret_string, secret_binary]
  }
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count               = var.rotation_lambda_arn != null ? 1 : 0
  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = try(var.rotation_rules.automatically_after_days, null)
    schedule_expression      = try(var.rotation_rules.schedule_expression, null)
    duration                 = try(var.rotation_rules.duration, null)
  }
}

resource "aws_secretsmanager_secret_policy" "this" {
  count      = var.policy != "" ? 1 : 0
  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = var.policy
}
