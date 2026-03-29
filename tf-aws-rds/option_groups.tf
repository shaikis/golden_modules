# ---------------------------------------------------------------------------
# Custom Option Group
# Primarily used by SQL Server and MySQL for engine-specific features:
#   SQL Server: SQLSERVER_AGENT, TDE, SSRS, SSAS, Native Backup & Restore
#   MySQL:      MARIADB_AUDIT_PLUGIN, MEMCACHED, etc.
# ---------------------------------------------------------------------------
resource "aws_db_option_group" "this" {
  count = var.create_option_group ? 1 : 0

  name                     = "${local.name}-og"
  option_group_description = coalesce(var.option_group_description, "Option group for ${local.name}")
  engine_name              = var.option_group_engine_name
  major_engine_version     = var.option_group_major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name                    = option.value.option_name
      port                           = lookup(option.value, "port", null)
      db_security_group_memberships  = lookup(option.value, "db_security_group_memberships", null)
      vpc_security_group_memberships = lookup(option.value, "vpc_security_group_memberships", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
