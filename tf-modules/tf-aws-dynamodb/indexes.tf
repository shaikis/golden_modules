# ---------------------------------------------------------------------------
# GSIs and LSIs are defined inline in tables.tf and global_tables.tf via
# dynamic blocks.  This file exists as an explicit placeholder so the module
# structure is self-documenting and future index-only resources (e.g. a
# standalone aws_dynamodb_table_item seeder or index-specific IAM conditions)
# can be added here without touching tables.tf.
# ---------------------------------------------------------------------------
