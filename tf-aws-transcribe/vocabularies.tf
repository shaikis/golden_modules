resource "aws_transcribe_vocabulary" "this" {
  for_each = var.create_vocabularies ? var.vocabularies : {}

  vocabulary_name     = "${local.name_prefix}${each.key}"
  language_code       = each.value.language_code
  phrases             = length(each.value.phrases) > 0 ? each.value.phrases : null
  vocabulary_file_uri = each.value.vocabulary_file_uri

  tags = merge(local.tags, each.value.tags)
}
