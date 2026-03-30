# tf-aws-fsx-dr-control Examples

Runnable examples for the [`tf-aws-fsx-dr-control`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — deploys the Step Functions state machine and Lambda functions for FSx ONTAP DR switchover, wired to a Route 53 DNS record and an SNS notification topic |

## Architecture

```mermaid
graph TB
    subgraph "tf-aws-fsx-dr-control basic example"
        SM["Step Functions\nState Machine\n(DR Switchover Workflow)"]
        LMB["Lambda Functions\n(Switchover Logic)"]
        R53["Route 53 CNAME\n(DNS Cutover)"]
        SNS["SNS Topic\n(Notifications)"]
        SEC["Secrets Manager\n(allowed_secret_arns)"]

        SM --> LMB
        LMB -->|update DNS| R53
        LMB -->|publish events| SNS
        LMB -->|read credentials| SEC
    end

    VPC["VPC\n(lambda_subnet_ids /\nsecurity_group_ids)"] --> LMB
    OPS["Operator / EventBridge"] -->|start execution| SM
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply
```
