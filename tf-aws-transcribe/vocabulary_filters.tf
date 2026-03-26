resource "aws_transcribe_vocabulary_filter" "this" {
  for_each = var.create_vocabulary_filters ? var.vocabulary_filters : {}

  vocabulary_filter_name     = "${local.name_prefix}${each.key}"
  language_code              = each.value.language_code
  words                      = length(each.value.words) > 0 ? each.value.words : null
  vocabulary_filter_file_uri = each.value.vocabulary_filter_file_uri

  tags = merge(local.tags, each.value.tags)
}
