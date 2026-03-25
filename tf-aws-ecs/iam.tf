# ---------------------------------------------------------------------------
# Task Execution Role (one shared for all tasks)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "execution" {
  name = "${local.name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]

  tags = local.tags
}
