resource "aws_polly_lexicon" "this" {
  for_each = var.create_lexicons ? var.lexicons : {}

  name    = each.key
  content = each.value.content
}
