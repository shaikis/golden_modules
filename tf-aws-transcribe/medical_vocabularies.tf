resource "aws_transcribe_medical_vocabulary" "this" {
  for_each = var.create_medical_vocabularies ? var.medical_vocabularies : {}

  vocabulary_name     = "${local.name_prefix}${each.key}"
  language_code       = each.value.language_code
  vocabulary_file_uri = each.value.vocabulary_file_uri

  tags = merge(local.tags, each.value.tags)
}
