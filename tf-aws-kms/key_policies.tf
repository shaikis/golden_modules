data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Per-key policy documents
# Each key gets its own merged policy built from four composable parts:
#   1. Root account admin (always present — prevents lockout)
#   2. Key administrators
#   3. Key users
#   4. AWS service principals
#   5. Cross-account principals (optional)
# ---------------------------------------------------------------------------

# --- 1. Root admin (one document shared across all keys) -------------------
data "aws_iam_policy_document" "root_admin" {
  statement {
    sid    = "EnableRootAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

# --- 2. Key administrators (per key) ---------------------------------------
data "aws_iam_policy_document" "key_admins" {
  for_each = { for k, v in var.keys : k => v if length(v.admin_principals) > 0 }

  statement {
    sid    = "KeyAdministrators"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = each.value.admin_principals
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }
}

# --- 3. Key users (per key) ------------------------------------------------
data "aws_iam_policy_document" "key_users" {
  for_each = { for k, v in var.keys : k => v if length(v.user_principals) > 0 }

  statement {
    sid    = "KeyUsers"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = each.value.user_principals
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

# --- 4. AWS service principals (per key) -----------------------------------
data "aws_iam_policy_document" "service_principals" {
  for_each = { for k, v in var.keys : k => v if length(v.service_principals) > 0 }

  statement {
    sid    = "AWSServicePrincipals"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = each.value.service_principals
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# --- 5. Cross-account principals (per key) ---------------------------------
data "aws_iam_policy_document" "cross_account" {
  for_each = { for k, v in var.keys : k => v if length(v.cross_account_principals) > 0 }

  statement {
    sid    = "CrossAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = each.value.cross_account_principals
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

# --- Merged policy per key -------------------------------------------------
# Always include root_admin. Layer the optional documents on top via
# override_policy_documents so later SIDs win on conflicts.
data "aws_iam_policy_document" "merged" {
  for_each = var.keys

  source_policy_documents = compact([
    data.aws_iam_policy_document.root_admin.json,
    try(data.aws_iam_policy_document.key_admins[each.key].json, null),
    try(data.aws_iam_policy_document.key_users[each.key].json, null),
    try(data.aws_iam_policy_document.service_principals[each.key].json, null),
    try(data.aws_iam_policy_document.cross_account[each.key].json, null),
  ])
}

# ---------------------------------------------------------------------------
# Replica key policies (admin + users only; no service principals needed
# since replicas are consumed the same way as primary keys)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "replica_admins" {
  for_each = { for k, v in var.replica_keys : k => v if length(v.admin_principals) > 0 }

  statement {
    sid    = "KeyAdministrators"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = each.value.admin_principals
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "replica_users" {
  for_each = { for k, v in var.replica_keys : k => v if length(v.user_principals) > 0 }

  statement {
    sid    = "KeyUsers"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = each.value.user_principals
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "replica_merged" {
  for_each = var.replica_keys

  source_policy_documents = compact([
    data.aws_iam_policy_document.root_admin.json,
    try(data.aws_iam_policy_document.replica_admins[each.key].json, null),
    try(data.aws_iam_policy_document.replica_users[each.key].json, null),
  ])
}
