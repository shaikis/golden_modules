resource "aws_redshift_data_share_authorization" "this" {
  for_each = var.create_data_shares ? var.data_share_authorizations : {}

  data_share_arn      = each.value.data_share_arn
  consumer_identifier = each.value.consumer_identifier
  allow_writes        = each.value.allow_writes
}

resource "aws_redshift_data_share_consumer_association" "this" {
  for_each = var.create_data_shares ? var.data_share_consumer_associations : {}

  data_share_arn           = each.value.data_share_arn
  associate_entire_account = each.value.associate_entire_account
  consumer_arn             = each.value.consumer_arn
  consumer_region          = each.value.consumer_region
}
