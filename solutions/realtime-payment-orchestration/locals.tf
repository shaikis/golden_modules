locals {
  common_tags = merge(
    {
      Solution    = "realtime-payment-orchestration"
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Payment Kafka topics
  kafka_topics = [
    "payment.initiated",
    "payment.validated",
    "payment.rejected",
    "payment.risk-scored",
    "payment.executing",
    "payment.executed",
    "payment.settled",
    "payment.failed",
    "payment.reconciled",
    "notification.outbound",
  ]

  # Lambda microservices — name → S3 key + consumer topic + producer topic
  lambda_services = {
    payment-initiator = {
      description    = "Validates inbound payment request, creates idempotency record, publishes payment.initiated"
      s3_key         = "lambda/payment-initiator.zip"
      consumer_topic = null                    # triggered by API GW, not MSK
      producer_topic = "payment.initiated"
      timeout        = var.lambda_timeout_seconds
      memory         = var.lambda_memory_mb
    }
    payment-validator = {
      description    = "Sanctions screening, schema validation, publishes payment.validated or payment.rejected"
      s3_key         = "lambda/payment-validator.zip"
      consumer_topic = "payment.initiated"
      producer_topic = "payment.validated"
      timeout        = var.lambda_timeout_seconds
      memory         = var.lambda_memory_mb
    }
    risk-management = {
      description    = "ML-based fraud scoring, enriches validated payment event"
      s3_key         = "lambda/risk-management.zip"
      consumer_topic = "payment.validated"
      producer_topic = "payment.risk-scored"
      timeout        = var.lambda_timeout_seconds
      memory         = 1024  # higher memory for ML inference
    }
    payment-executor = {
      description    = "Routes payment to correct rail (SWIFT, ACH, RTP, SEPA), publishes payment.executed"
      s3_key         = "lambda/payment-executor.zip"
      consumer_topic = "payment.risk-scored"
      producer_topic = "payment.executed"
      timeout        = 90  # external rail calls may be slow
      memory         = var.lambda_memory_mb
    }
    settlement = {
      description    = "Updates ledger DynamoDB table, publishes payment.settled"
      s3_key         = "lambda/settlement.zip"
      consumer_topic = "payment.executed"
      producer_topic = "payment.settled"
      timeout        = var.lambda_timeout_seconds
      memory         = var.lambda_memory_mb
    }
    reconciliation = {
      description    = "End-of-day reconciliation, verifies settlement balances"
      s3_key         = "lambda/reconciliation.zip"
      consumer_topic = "payment.settled"
      producer_topic = "payment.reconciled"
      timeout        = 300  # batch-style, can be slow
      memory         = 1024
    }
    notification = {
      description    = "Sends payment status notifications to customers via SNS"
      s3_key         = "lambda/notification.zip"
      consumer_topic = "payment.settled"
      producer_topic = null
      timeout        = var.lambda_timeout_seconds
      memory         = 256
    }
  }
}
