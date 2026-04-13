# tf-aws-fsx-dr-control Examples

Runnable examples for the [`tf-aws-fsx-dr-control`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration for the DR control plane, plus example payloads for switchover, revert_switchover, failover, and failback |

## Scenario Map

```mermaid
flowchart TB
    B["basic example"] --> SW["switchover<br/>non-promoting"]
    B --> RV["revert_switchover"]
    B --> FO["failover<br/>DR promotion path"]
    B --> FB["failback<br/>post-recovery"]
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply
```
