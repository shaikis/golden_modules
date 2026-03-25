data "aws_iam_policy_document" "redshift_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "RedshiftAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "redshift_scheduler_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "RedshiftSchedulerAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.redshift.amazonaws.com"]
    }
  }
}

# ── Redshift Service Role ─────────────────────────────────────────────────────

resource "aws_iam_role" "redshift" {
  count = var.create_iam_role ? 1 : 0

  name               = "redshift-service-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume_role[0].json

  tags = merge(var.tags, {
    Name = "redshift-service-role-${data.aws_region.current.name}"
  })
}

resource "aws_iam_role_policy_attachment" "redshift_full_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.redshift[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

data "aws_iam_policy_document" "redshift_s3_access" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "S3ReadForCopyUnload"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "redshift_s3_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "redshift-s3-access-${data.aws_region.current.name}"
  description = "Allows Redshift to read/write S3 for COPY and UNLOAD commands"
  policy      = data.aws_iam_policy_document.redshift_s3_access[0].json

  tags = merge(var.tags, {
    Name = "redshift-s3-access-${data.aws_region.current.name}"
  })
}

resource "aws_iam_role_policy_attachment" "redshift_s3_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.redshift[0].name
  policy_arn = aws_iam_policy.redshift_s3_access[0].arn
}

data "aws_iam_policy_document" "redshift_glue_access" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "GlueCatalogReadForSpectrum"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
      "glue:CreateDatabase",
      "glue:CreateTable",
      "glue:DeleteDatabase",
      "glue:DeleteTable",
      "glue:UpdateTable",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "redshift_glue_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "redshift-glue-access-${data.aws_region.current.name}"
  description = "Allows Redshift Spectrum to query the Glue Data Catalog"
  policy      = data.aws_iam_policy_document.redshift_glue_access[0].json

  tags = merge(var.tags, {
    Name = "redshift-glue-access-${data.aws_region.current.name}"
  })
}

resource "aws_iam_role_policy_attachment" "redshift_glue_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.redshift[0].name
  policy_arn = aws_iam_policy.redshift_glue_access[0].arn
}

data "aws_iam_policy_document" "redshift_athena_access" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "AthenaFederatedQuery"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
      "athena:GetWorkGroup",
      "athena:ListWorkGroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "redshift_athena_access" {
  count = var.create_iam_role ? 1 : 0

  name        = "redshift-athena-access-${data.aws_region.current.name}"
  description = "Allows Redshift to run federated queries via Athena"
  policy      = data.aws_iam_policy_document.redshift_athena_access[0].json

  tags = merge(var.tags, {
    Name = "redshift-athena-access-${data.aws_region.current.name}"
  })
}

resource "aws_iam_role_policy_attachment" "redshift_athena_access" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.redshift[0].name
  policy_arn = aws_iam_policy.redshift_athena_access[0].arn
}

# ── Scheduled Actions Role ────────────────────────────────────────────────────

resource "aws_iam_role" "redshift_scheduler" {
  count = var.create_iam_role ? 1 : 0

  name               = "redshift-scheduler-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.redshift_scheduler_assume_role[0].json

  tags = merge(var.tags, {
    Name = "redshift-scheduler-role-${data.aws_region.current.name}"
  })
}

data "aws_iam_policy_document" "redshift_scheduler_policy" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid    = "RedshiftScheduledActions"
    effect = "Allow"
    actions = [
      "redshift:PauseCluster",
      "redshift:ResumeCluster",
      "redshift:ResizeCluster",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "redshift_scheduler_policy" {
  count = var.create_iam_role ? 1 : 0

  name        = "redshift-scheduler-policy-${data.aws_region.current.name}"
  description = "Allows the Redshift scheduler to pause, resume, and resize clusters"
  policy      = data.aws_iam_policy_document.redshift_scheduler_policy[0].json

  tags = merge(var.tags, {
    Name = "redshift-scheduler-policy-${data.aws_region.current.name}"
  })
}

resource "aws_iam_role_policy_attachment" "redshift_scheduler_policy" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.redshift_scheduler[0].name
  policy_arn = aws_iam_policy.redshift_scheduler_policy[0].arn
}
