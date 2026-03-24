locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  # FIFO queues must end in .fifo
  queue_name = var.fifo_queue ? "${local.name}.fifo" : local.name
  dlq_name   = var.fifo_queue ? "${local.name}-dlq.fifo" : "${local.name}-dlq"

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-sqs"
  }
  tags = merge(local.default_tags, var.tags)
}
