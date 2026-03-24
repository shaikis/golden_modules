# ---------------------------------------------------------------------------
# KMS Grants
# Use grants when an AWS service cannot be named in a key policy's Principal
# block (e.g. Firehose, certain Lambda invocation patterns) or when you need
# to delegate usage rights without modifying the key policy.
# ---------------------------------------------------------------------------
resource "aws_kms_grant" "this" {
  for_each = var.grants

  name               = each.key
  key_id             = aws_kms_key.this[each.value.key_name].key_id
  grantee_principal  = each.value.grantee_principal
  operations         = each.value.operations
  retiring_principal = each.value.retiring_principal

  dynamic "constraints" {
    for_each = (
      each.value.encryption_context_equals != null ||
      each.value.encryption_context_subset != null
    ) ? [1] : []
    content {
      encryption_context_equals = each.value.encryption_context_equals
      encryption_context_subset = each.value.encryption_context_subset
    }
  }
}
