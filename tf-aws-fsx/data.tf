data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "ontap_fsx_admin" {
  count = var.ontap != null && var.ontap.fsx_admin_password_secret_id != null ? 1 : 0

  secret_id = var.ontap.fsx_admin_password_secret_id
}

data "aws_secretsmanager_secret_version" "windows_self_managed_ad_password" {
  count = (
    var.windows != null &&
    var.windows.active_directory_id == null &&
    var.windows.self_managed_ad != null &&
    var.windows.self_managed_ad.password_secret_id != null
  ) ? 1 : 0

  secret_id = var.windows.self_managed_ad.password_secret_id
}

data "aws_secretsmanager_secret_version" "ontap_svm_admin_password" {
  for_each = var.ontap != null ? {
    for svm_key, svm in var.ontap.svms : svm_key => svm
    if svm.svm_admin_password_secret_id != null
  } : {}

  secret_id = each.value.svm_admin_password_secret_id
}

data "aws_secretsmanager_secret_version" "ontap_active_directory_password" {
  for_each = var.ontap != null ? {
    for svm_key, svm in var.ontap.svms : svm_key => svm.active_directory
    if svm.active_directory != null && svm.active_directory.password_secret_id != null
  } : {}

  secret_id = each.value.password_secret_id
}

data "aws_secretsmanager_secret_version" "snapmirror_source_admin_password" {
  count = (
    var.enable_ontap_snapmirror &&
    var.ontap_snapmirror != null &&
    var.ontap_snapmirror.source_admin_password_secret_id != null
  ) ? 1 : 0

  secret_id = var.ontap_snapmirror.source_admin_password_secret_id
}

data "aws_secretsmanager_secret_version" "snapmirror_destination_admin_password" {
  count = (
    var.enable_ontap_snapmirror &&
    var.ontap_snapmirror != null &&
    var.ontap_snapmirror.destination_admin_password_secret_id != null
  ) ? 1 : 0

  secret_id = var.ontap_snapmirror.destination_admin_password_secret_id
}
