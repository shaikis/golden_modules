resource "aws_cloudwatch_log_group" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  name              = "/aws/vpc/flowlogs/${local.name}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.flow_log_kms_key_id

  tags = merge(local.tags, { Name = "${local.name}-flow-log-lg" })
}

resource "aws_iam_role" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0
  name  = "${local.name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0
  name  = "${local.name}-vpc-flow-log-policy"
  role  = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_log[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  vpc_id       = aws_vpc.this.id
  traffic_type = var.flow_log_traffic_type
  iam_role_arn = local.flow_log_to_cloudwatch ? aws_iam_role.flow_log[0].arn : null
  log_destination = (
    local.flow_log_to_cloudwatch ? aws_cloudwatch_log_group.flow_log[0].arn
    : var.flow_log_destination_arn
  )
  log_destination_type = var.flow_log_destination_type

  tags = merge(local.tags, { Name = "${local.name}-flow-log" })
}
