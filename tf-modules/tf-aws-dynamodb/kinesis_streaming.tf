# ---------------------------------------------------------------------------
# DynamoDB → Kinesis Data Streams integration
# ---------------------------------------------------------------------------

locals {
  # Only tables that have a kinesis_stream_arn set
  kinesis_tables = {
    for k, v in var.tables : k => v
    if v.kinesis_stream_arn != null
  }
}

resource "aws_dynamodb_kinesis_streaming_destination" "this" {
  for_each = local.kinesis_tables

  table_name = aws_dynamodb_table.this[each.key].name
  stream_arn = each.value.kinesis_stream_arn
}
