# =============================================================================
# tf-aws-cloudwatch — Module Index
#
# All resources are organized into dedicated feature files.
# Enable/disable each feature independently using its toggle variable.
#
# ── Core (always active) ──────────────────────────────────────────────────────
#   versions.tf            — Terraform + provider version constraints
#   data.tf                — Shared data sources (partition, region, account)
#   locals.tf              — Core locals: prefix, common_tags, effective_sns_arn
#   variables.tf           — Core variables: naming, tags, SNS, notification integrations
#   sns.tf                 — SNS topic (BYO or create) + all subscriptions
#   outputs.tf             — All module outputs
#
# ── Alarm Features (toggle with variable maps or enable_xxx = true) ───────────
#   alarms_generic.tf      — Any AWS/custom metric + anomaly detection + composite
#   alarms_log_filters.tf  — CloudWatch log metric filters with optional alarms
#   alarms_asg.tf          — Auto Scaling Group CPU high/low, maxed-out, below-min
#   alarms_backup.tf       — AWS Backup job/restore/copy failures
#   alarms_rds.tf          — RDS CPU, memory, storage, connections, replica lag
#   alarms_api_gateway.tf  — API Gateway 5xx/4xx errors, latency p99
#   alarms_ecs.tf          — ECS service CPU, memory, running task count
#   alarms_alb.tf          — ALB 5xx/4xx errors, target response time, unhealthy hosts
#   alarms_elasticache.tf  — ElastiCache CPU, evictions, memory, connections, replica lag
#   alarms_acm.tf          — ACM certificate expiry (warning at 30d, critical at 7d)
#   synthetics.tf          — CloudWatch Synthetics canaries for endpoint health checks
#
# ── CloudTrail / Security (toggle with enable_xxx = true) ────────────────────
#   cloudtrail_deletion.tf — Alert + actor identity when EC2/RDS/S3/Lambda etc. deleted
#   cloudtrail_stop.tf     — Alert + actor identity when EC2/RDS instances stopped
#   security_alerts.tf     — IAM changes, security group changes, S3 policy, GuardDuty
#   health_events.tf       — AWS Health service issues + maintenance notifications
#
# ── Operational Features ──────────────────────────────────────────────────────
#   cost_anomaly.tf        — AWS Cost Anomaly Detection (ML-based cost spike alerts)
#   eventbridge_routing.tf — Route alarm state changes to SQS/Lambda for ITSM
#   dashboard.tf           — Auto-generated CloudWatch operations dashboard
# =============================================================================
