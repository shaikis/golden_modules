# tf-aws-waf Examples

Runnable examples for the [`tf-aws-waf`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [payment-api-protection](payment-api-protection/) | Full protection stack for a fintech payment API attached to CloudFront — OWASP managed rules, bot control, OFAC country geo-blocking, per-IP rate limiting, trusted partner bank allow-listing, body size constraints, and compliance logging to S3 |

## Architecture

```mermaid
graph TB
    Client((Client)) --> CF["CloudFront Distribution\n(WAF scope: CLOUDFRONT)"]

    subgraph WAF["AWS WAF Web ACL — payment-api-protection"]
        direction TB
        P5["Priority 5\nAllow trusted partner banks\n(IP set)"]
        P6["Priority 6\nAllow internal monitoring\n(IP set)"]
        P10["Priority 10\nAWS Common Rule Set\n(OWASP Top 10)"]
        P20["Priority 20\nKnown Bad Inputs\n(Log4Shell, Spring4Shell)"]
        P30["Priority 30\nSQL Injection Rule Set"]
        P40["Priority 40\nAWS IP Reputation List"]
        P50["Priority 50\nAnonymous IP List\n(COUNT mode)"]
        P60["Priority 60\nBot Control\n(COUNT mode)"]
        P70["Priority 70\nGeo-Block OFAC countries\nKP, IR, SY, CU, BY"]
        P80["Priority 80-81\nRate Limit per IP / X-Forwarded-For\n(block > threshold / 5 min)"]
        P90["Priority 90-92\nCustom Rules\noversized body · SQLi URI · XSS QS"]
    end

    CF --> WAF
    WAF -->|"blocked requests"| S3["S3 Log Bucket\n(compliance)"]
    WAF -->|"allowed"| API["Payment API Origin"]

    TrustedBanks["Partner Bank CIDRs\n(IP Set)"] --> P5
    Monitoring["Monitoring CIDRs\n(IP Set)"] --> P6
```

## Quick Start

```bash
cd payment-api-protection/
terraform init
terraform apply -var-file="dev.tfvars"
```
