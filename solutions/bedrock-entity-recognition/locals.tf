locals {
  prefix = "${var.name}-${var.environment}"

  tags = merge(
    {
      Solution    = "bedrock-entity-recognition"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
