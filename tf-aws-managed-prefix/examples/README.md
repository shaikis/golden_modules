# tf-aws-managed-prefix Examples

Runnable examples for the [`tf-aws-managed-prefix`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](.) | Minimal configuration — create multiple named managed prefix lists (internal, external, partners) from CIDR lists with automatic duplicate removal |

## Architecture

```mermaid
graph TB
    subgraph Input["tfvars Input"]
        Internal["internal\n10.0.0.0/24\n10.0.1.0/24"]
        External["external\n0.0.0.0/0"]
        Partners["partners\n172.16.0.0/16\n172.16.1.0/24"]
    end

    subgraph Module["tf-aws-managed-prefix (for_each)"]
        DedupLogic["Duplicate CIDR\nremoval"]
        PL1["Managed Prefix List\ndev-internal-pl"]
        PL2["Managed Prefix List\ndev-external-pl"]
        PL3["Managed Prefix List\ndev-partner-pl"]
    end

    subgraph Consumers["Referenced by"]
        SG["Security Group\nIngress Rules"]
        NACL["Network ACL\nRules"]
        RT["Route Table\nEntries"]
        TGW["Transit Gateway\nRoute Tables"]
    end

    Internal --> DedupLogic --> PL1
    External --> DedupLogic --> PL2
    Partners --> DedupLogic --> PL3

    PL1 --> Consumers
    PL2 --> Consumers
    PL3 --> Consumers
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="terraform.tfvars"
```
