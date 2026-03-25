# ---------------------------------------------------------------------------
# Fine-grained IAM Roles and Policies for DynamoDB
# ---------------------------------------------------------------------------

locals {
  all_table_arns = concat(
    [for t in aws_dynamodb_table.this : t.arn],
    [for t in aws_dynamodb_table.global : t.arn]
  )

  all_table_stream_arns = concat(
    [for t in aws_dynamodb_table.this : t.stream_arn if t.stream_arn != null && t.stream_arn != ""],
    [for t in aws_dynamodb_table.global : t.stream_arn if t.stream_arn != null && t.stream_arn != ""]
  )

  # Index ARNs (wildcard) for all tables
  all_index_arns = concat(
    [for t in aws_dynamodb_table.this : "${t.arn}/index/*"],
    [for t in aws_dynamodb_table.global : "${t.arn}/index/*"]
  )

  assume_role_principals = length(var.iam_role_principal_arns) > 0 ? var.iam_role_principal_arns : [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ---------------------------------------------------------------------------
# Assume-role policy (shared)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = local.assume_role_principals
    }
  }
}

# ---------------------------------------------------------------------------
# Read-Only Policy
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "read_only" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid    = "DynamoDBReadOnly"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable",
      "dynamodb:ListTables",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DescribeGlobalTable",
      "dynamodb:DescribeGlobalTableSettings",
      "dynamodb:ListGlobalTables",
    ]
    resources = concat(local.all_table_arns, local.all_index_arns)
  }
}

resource "aws_iam_policy" "read_only" {
  count = var.create_iam_roles ? 1 : 0

  name        = "${var.name_prefix}-dynamodb-read-only"
  description = "Read-only access to ${var.name_prefix} DynamoDB tables"
  policy      = data.aws_iam_policy_document.read_only[0].json

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role" "read_only" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${var.name_prefix}-dynamodb-read-only-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  description        = "Read-only DynamoDB access"

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role_policy_attachment" "read_only" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.read_only[0].name
  policy_arn = aws_iam_policy.read_only[0].arn
}

# ---------------------------------------------------------------------------
# Read-Write Policy
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "read_write" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid    = "DynamoDBReadWrite"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable",
      "dynamodb:ListTables",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:TransactGetItems",
      "dynamodb:ConditionCheckItem",
    ]
    resources = concat(local.all_table_arns, local.all_index_arns)
  }
}

resource "aws_iam_policy" "read_write" {
  count = var.create_iam_roles ? 1 : 0

  name        = "${var.name_prefix}-dynamodb-read-write"
  description = "Read-write access to ${var.name_prefix} DynamoDB tables"
  policy      = data.aws_iam_policy_document.read_write[0].json

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role" "read_write" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${var.name_prefix}-dynamodb-read-write-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  description        = "Read-write DynamoDB access"

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role_policy_attachment" "read_write" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.read_write[0].name
  policy_arn = aws_iam_policy.read_write[0].arn
}

# ---------------------------------------------------------------------------
# Admin Policy
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "admin" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid       = "DynamoDBAdmin"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "admin" {
  count = var.create_iam_roles ? 1 : 0

  name        = "${var.name_prefix}-dynamodb-admin"
  description = "Full DynamoDB admin access"
  policy      = data.aws_iam_policy_document.admin[0].json

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role" "admin" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${var.name_prefix}-dynamodb-admin-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  description        = "Full DynamoDB admin access"

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role_policy_attachment" "admin" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.admin[0].name
  policy_arn = aws_iam_policy.admin[0].arn
}

# ---------------------------------------------------------------------------
# Stream Consumer Policy
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "stream_consumer" {
  count = var.create_iam_roles && length(local.all_table_stream_arns) > 0 ? 1 : 0

  statement {
    sid    = "DynamoDBStreamConsumer"
    effect = "Allow"
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
    ]
    resources = length(local.all_table_stream_arns) > 0 ? local.all_table_stream_arns : ["*"]
  }
}

resource "aws_iam_policy" "stream_consumer" {
  count = var.create_iam_roles && length(local.all_table_stream_arns) > 0 ? 1 : 0

  name        = "${var.name_prefix}-dynamodb-stream-consumer"
  description = "DynamoDB Streams consumer access"
  policy      = data.aws_iam_policy_document.stream_consumer[0].json

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role" "stream_consumer" {
  count = var.create_iam_roles && length(local.all_table_stream_arns) > 0 ? 1 : 0

  name               = "${var.name_prefix}-dynamodb-stream-consumer-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  description        = "DynamoDB Streams consumer"

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role_policy_attachment" "stream_consumer" {
  count = var.create_iam_roles && length(local.all_table_stream_arns) > 0 ? 1 : 0

  role       = aws_iam_role.stream_consumer[0].name
  policy_arn = aws_iam_policy.stream_consumer[0].arn
}

# ---------------------------------------------------------------------------
# Fine-grained attribute-level policy with LeadingKey condition
# (template — attach to application IAM roles as needed)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "per_user_isolation" {
  count = var.create_iam_roles ? 1 : 0

  statement {
    sid    = "DynamoDBLeadingKeyIsolation"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = local.all_table_arns

    # Restrict access so each principal can only access rows where the
    # partition key equals their own IAM identity (user_id = caller user ID)
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:LeadingKeys"
      values   = ["$${aws:userId}"]
    }

    # Optionally restrict which attributes are readable/writable
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:Attributes"
      values = [
        "user_id",
        "email",
        "created_at",
        "updated_at",
        "status",
      ]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "dynamodb:Select"
      values   = ["SPECIFIC_ATTRIBUTES"]
    }
  }
}

resource "aws_iam_policy" "per_user_isolation" {
  count = var.create_iam_roles ? 1 : 0

  name        = "${var.name_prefix}-dynamodb-per-user-isolation"
  description = "Fine-grained per-user DynamoDB isolation via LeadingKey condition"
  policy      = data.aws_iam_policy_document.per_user_isolation[0].json

  tags = merge(var.tags, { ManagedBy = "terraform" })
}
