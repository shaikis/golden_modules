# tf-aws-route53 Examples

Runnable examples for the [`tf-aws-route53`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — single public hosted zone with common record types (A, AAAA, CNAME, MX, TXT, NS, CAA) |
| [complete](complete/) | Full feature showcase — public and private zones, delegation sets, all routing policies, alias records, health checks, DNSSEC, Route 53 Resolver endpoints and forwarding rules, and DNS Firewall |
| [failover](failover/) | Active-passive multi-region failover routing across us-east-1 and eu-west-1, combined with weighted canary deployments and latency-based routing |
| [rds-alb-paris-frankfurt](rds-alb-paris-frankfurt/) | Multi-service Paris/Frankfurt failover — ALB weighted records with health-check-driven automatic failover, and private-zone RDS CNAME failover driven by CloudWatch alarms |

## Architecture

```mermaid
graph TB
    subgraph PublicZone["Public Hosted Zone"]
        A["A / AAAA Records"]
        CNAME["CNAME (www)"]
        MX["MX (email)"]
        TXT["TXT (SPF, DMARC)"]
        ALB_ALIAS["Alias → ALB"]
        FAILOVER["Failover Records\nPRIMARY / SECONDARY"]
        WEIGHTED["Weighted Records\nprod 90% / canary 10%"]
        LATENCY["Latency Records\nus-east-1 / eu-west-1"]
    end

    subgraph PrivateZone["Private Hosted Zone (complete / rds-alb)"]
        RDS_CNAME["RDS CNAME\n(failover)"]
        INT_A["Internal A Records"]
    end

    subgraph Resolver["Route 53 Resolver (complete)"]
        Inbound["Inbound Endpoint"]
        Outbound["Outbound Endpoint"]
        FwdRule["Forwarding Rule\ncorp.example.com"]
    end

    subgraph Firewall["DNS Firewall (complete)"]
        DomainList["Block List\n(crypto-mining domains)"]
        RuleGroup["Rule Group → NXDOMAIN"]
    end

    HC1["Health Check\nHTTPS /health"] --> FAILOVER
    CWAlarm["CloudWatch Alarm\n(RDS connections)"] --> RDS_CNAME
    OnPrem["On-Premises DNS"] <--> Outbound
    OnPrem --> Inbound
    FwdRule --> Outbound
    VPC["VPC"] --> Firewall
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
