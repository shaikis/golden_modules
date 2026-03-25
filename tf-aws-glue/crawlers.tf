# ---------------------------------------------------------------------------
# Glue Crawlers
# ---------------------------------------------------------------------------

locals {
  # Determine the effective IAM role ARN for each crawler.
  # If the caller supplies a role_arn use it; otherwise fall back to the
  # module-managed service role (when create_iam_role = true).
  crawler_role_arns = {
    for k, v in var.crawlers :
    k => coalesce(v.role_arn, var.create_iam_role ? aws_iam_role.glue_service[0].arn : "")
  }
}

resource "aws_glue_crawler" "this" {
  for_each = var.create_crawlers ? var.crawlers : {}

  name          = "${var.name_prefix}${each.key}"
  database_name = each.value.database_name
  role          = local.crawler_role_arns[each.key]
  description   = each.value.description
  schedule      = each.value.schedule
  classifiers   = each.value.classifiers != null ? each.value.classifiers : []
  table_prefix  = each.value.table_prefix
  configuration = each.value.configuration

  security_configuration = each.value.security_configuration

  # ---- S3 targets -------------------------------------------------------
  dynamic "s3_target" {
    for_each = each.value.s3_targets != null ? each.value.s3_targets : []
    content {
      path            = s3_target.value.path
      exclusions      = s3_target.value.exclusions != null ? s3_target.value.exclusions : []
      connection_name = s3_target.value.connection_name
      sample_size     = s3_target.value.sample_size
    }
  }

  # ---- JDBC targets -----------------------------------------------------
  dynamic "jdbc_target" {
    for_each = each.value.jdbc_targets != null ? each.value.jdbc_targets : []
    content {
      connection_name = jdbc_target.value.connection_name
      path            = jdbc_target.value.path
      exclusions      = jdbc_target.value.exclusions != null ? jdbc_target.value.exclusions : []
    }
  }

  # ---- Catalog targets --------------------------------------------------
  dynamic "catalog_target" {
    for_each = each.value.catalog_targets != null ? each.value.catalog_targets : []
    content {
      database_name = catalog_target.value.database_name
      tables        = catalog_target.value.tables
    }
  }

  # ---- DynamoDB targets -------------------------------------------------
  dynamic "dynamodb_target" {
    for_each = each.value.dynamodb_targets != null ? each.value.dynamodb_targets : []
    content {
      path      = dynamodb_target.value.path
      scan_all  = dynamodb_target.value.scan_all
      scan_rate = dynamodb_target.value.scan_rate
    }
  }

  # ---- Kafka targets ----------------------------------------------------
  dynamic "kafka_target" {
    for_each = each.value.kafka_targets != null ? each.value.kafka_targets : []
    content {
      connection_name  = kafka_target.value.connection_name
      topic_name       = kafka_target.value.topic_name
      starting_offsets = kafka_target.value.starting_offsets
    }
  }

  # ---- Delta Lake targets -----------------------------------------------
  dynamic "delta_target" {
    for_each = each.value.delta_target != null ? each.value.delta_target : []
    content {
      delta_tables    = delta_target.value.delta_tables
      write_manifest  = delta_target.value.write_manifest
      connection_name = delta_target.value.connection_name
    }
  }

  # ---- Schema change policy ---------------------------------------------
  dynamic "schema_change_policy" {
    for_each = each.value.schema_change_policy != null ? [each.value.schema_change_policy] : [{}]
    content {
      delete_behavior = lookup(schema_change_policy.value, "delete_behavior", "LOG")
      update_behavior = lookup(schema_change_policy.value, "update_behavior", "UPDATE_IN_DATABASE")
    }
  }

  # ---- Recrawl policy ---------------------------------------------------
  recrawl_policy {
    recrawl_behavior = each.value.recrawl_policy != null ? each.value.recrawl_policy : "CRAWL_NEW_FOLDERS_ONLY"
  }

  # ---- Lineage configuration --------------------------------------------
  lineage_configuration {
    crawler_lineage_settings = each.value.lineage ? "ENABLE" : "DISABLE"
  }

  # ---- Lake Formation configuration ------------------------------------
  dynamic "lake_formation_configuration" {
    for_each = each.value.lake_formation_configuration != null ? [each.value.lake_formation_configuration] : []
    content {
      account_id                     = lake_formation_configuration.value.account_id
      use_lake_formation_credentials = lake_formation_configuration.value.use_lake_formation_credentials
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}${each.key}" })

  depends_on = [
    aws_glue_catalog_database.this,
    aws_iam_role_policy_attachment.glue_managed,
    aws_iam_role_policy.glue_inline,
  ]
}
