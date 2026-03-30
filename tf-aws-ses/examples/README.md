# tf-aws-ses Examples

Runnable examples for the [`tf-aws-ses`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — single verified domain with DKIM signing only; no configuration sets, receipt rules, templates, or IAM roles |
| [complete](complete/) | Full configuration with multiple domain and email identities, transactional and marketing configuration sets, SNS/CloudWatch/Firehose event destinations, inbound receipt rules, email templates, and auto-created IAM roles |

## Architecture

```mermaid
graph TB
    subgraph SES["Amazon SES"]
        DomainId["Domain Identity<br/>(example.com)"]
        EmailId["Email Identities<br/>(noreply@, support@)"]
        ConfigSet_T["Config Set: transactional"]
        ConfigSet_M["Config Set: marketing"]
        RuleSet["Receipt Rule Set<br/>(inbound-example-com)"]
        Templates["Email Templates<br/>(welcome, password_reset, invoice)"]
    end

    DomainId -->|DKIM CNAME records| DNS["DNS Registrar"]
    DomainId --> ConfigSet_T
    DomainId --> ConfigSet_M

    ConfigSet_T -->|BOUNCE/COMPLAINT| SNS_Bounce["SNS Topic<br/>(bounce/complaint)"]
    ConfigSet_T -->|SEND/DELIVERY| CW["CloudWatch Metrics"]
    ConfigSet_M -->|all events| Firehose["Kinesis Firehose"]
    ConfigSet_M -->|OPEN/CLICK| CW

    RuleSet --> Rule1["Rule: store_and_notify<br/>recipients: inbound@, support@"]
    RuleSet --> Rule2["Rule: spam_filter"]

    Rule1 -->|position 1| S3["S3 Bucket<br/>(inbound mail)"]
    Rule1 -->|position 2| SNS_Inbound["SNS Topic<br/>(inbound)"]
    Rule1 -->|position 3| Lambda["Lambda<br/>(inbound processor)"]
    Rule2 -->|bounce| BounceAction["Bounce 550 response"]

    IAM["IAM Roles<br/>(firehose + s3)"] --> Firehose
    IAM --> S3
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply
```

For the complete example, supply the required variable values first:

```bash
cd complete/
terraform init
terraform apply \
  -var="inbound_bucket_name=my-ses-inbound" \
  -var="sns_bounce_topic_arn=arn:aws:sns:us-east-1:123456789012:ses-bounces" \
  -var="sns_inbound_topic_arn=arn:aws:sns:us-east-1:123456789012:ses-inbound" \
  -var="firehose_stream_arn=arn:aws:firehose:us-east-1:123456789012:deliverystream/ses-marketing" \
  -var="inbound_processor_lambda_arn=arn:aws:lambda:us-east-1:123456789012:function:ses-processor"
```
