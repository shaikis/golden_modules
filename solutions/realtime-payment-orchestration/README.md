# Real-Time Payment Orchestration on AWS

> Based on the AWS Architecture blog: [Modernization of Real-Time Payment Orchestration on AWS](https://aws.amazon.com/blogs/architecture/modernization-of-real-time-payment-orchestration-on-aws/)

## Architecture Overview

```
                                  ┌──────────────────────────────────────────────────────┐
                                  │              PRIMARY REGION (us-east-1)               │
                                  │                                                        │
Internet ──► CloudFront ──► WAF ──► API Gateway ──► Lambda Microservices ──► MSK (Kafka)  │
           (Global CDN)  (Security)  (HTTP API)    ┌──────────────────────┐  ┌──────────┐ │
                                                   │ payment-initiator    │  │ Topics:  │ │
                                                   │ payment-validator    │  │ payments │ │
                                                   │ payment-executor     │  │ routing  │ │
                                                   │ settlement           │  │ settled  │ │
                                                   │ reconciliation       │  │ failed   │ │
                                                   │ risk-management      │  │ dlq      │ │
                                                   │ notification         │  └────┬─────┘ │
                                                   └──────────────────────┘       │        │
                                                             │                    │        │
                                                             ▼                    ▼        │
                                                       DynamoDB Global       MSK Replicator│
                                                       (transactions,        (cross-region)│
                                                        idempotency,                       │
                                                        audit trail)                       │
                                  └──────────────────────────────────────────────────────┘
                                              │ (replication)
                                  ┌──────────────────────────────────────────────────────┐
                                  │              FAILOVER REGION (us-west-2)             │
                                  │          (same architecture, standby MSK cluster)    │
                                  └──────────────────────────────────────────────────────┘
```

## Payment Flow (Event-Driven)

1. **Client** → CloudFront → WAF → API Gateway `/v1/payments`
2. **payment-initiator Lambda** → validates request, creates idempotency record in DynamoDB, publishes `payment.initiated` to MSK
3. **payment-validator Lambda** → consumes `payment.initiated`, runs sanctions/AML checks, publishes `payment.validated` or `payment.rejected`
4. **risk-management Lambda** → consumes `payment.validated`, scores risk, enriches event
5. **payment-executor Lambda** → consumes risk-scored event, routes to payment rail, publishes `payment.executing`
6. **settlement Lambda** → consumes `payment.executed`, records in ledger DynamoDB table, publishes `payment.settled`
7. **reconciliation Lambda** → consumes `payment.settled`, performs end-of-day reconciliation
8. **notification Lambda** → consumes all terminal events, sends SNS alerts

## Infrastructure Modules Used

| Module | Purpose |
|---|---|
| `tf-aws-vpc` | Isolated network with private subnets for MSK/Lambda |
| `tf-aws-kms` | Encryption keys for MSK, DynamoDB, SQS, S3 |
| `tf-aws-security-group` | MSK, Lambda, API GW security rules |
| `tf-aws-waf` | Payment API protection (rate limiting, OWASP, geo) |
| `tf-aws-cloudfront` | Global edge routing with WAF attachment |
| `tf-aws-apigateway` | HTTP API with JWT auth, throttling |
| `tf-aws-data-e-msk` | Kafka event bus + MSK Replicator (cross-region) |
| `tf-aws-lambda` | 7 payment microservice functions |
| `tf-aws-dynamodb` | Transactions, idempotency, audit, ledger tables |
| `tf-aws-sqs` | Dead-letter queues for failed payment events |
| `tf-aws-sns` | Payment status notification fanout |
| `tf-aws-secretsmanager` | MSK SCRAM credentials, API keys |
| `tf-aws-cloudwatch` | Dashboards, alarms, log retention |
| `tf-aws-s3` | Lambda code, audit logs, WAF logs |

## Deployment

```bash
cd solutions/realtime-payment-orchestration

# Initialize
terraform init

# Review plan
terraform plan -var-file="environments/prod.tfvars"

# Deploy
terraform apply -var-file="environments/prod.tfvars"
```

## Key Design Decisions

- **Parallel processing**: Each Lambda microservice consumes its own Kafka topic independently — no sequential chaining
- **Idempotency**: Every payment is keyed by `payment_id` in DynamoDB with conditional writes — safe to retry
- **Circuit breaker**: SQS DLQs catch failed Lambda invocations — CloudWatch alarm triggers SNS when DLQ depth > 0
- **Zero-downtime failover**: MSK Replicator keeps standby region in sync — Route53 health check fails over DNS
- **1000+ TPS**: MSK with 3 brokers + Lambda auto-scaling + DynamoDB on-demand handles bursts
- **99.999% uptime**: Multi-AZ MSK + DynamoDB global tables + CloudFront + Route53 failover
