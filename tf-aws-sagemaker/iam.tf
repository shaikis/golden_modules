data "aws_iam_policy_document" "sagemaker_assume" {
  count = var.create_iam_role ? 1 : 0

  statement {
    sid     = "SageMakerAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sagemaker" {
  count = var.create_iam_role ? 1 : 0

  name               = "${local.name_prefix}sagemaker-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume[0].json
  description        = "SageMaker execution role managed by tf-aws-sagemaker module."

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_full" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.sagemaker[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSageMakerFullAccess"
}
