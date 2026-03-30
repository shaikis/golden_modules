# tf-aws-app-recovery-controller — Examples

> Quick-start examples for the `tf-aws-app-recovery-controller` Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [payment-multi-region-failover](payment-multi-region-failover/) | Full active/passive multi-region failover for a real-time payment platform — ARC cluster, dual routing controls, assertion + gating safety rules, Route 53 health checks, readiness checks for MSK, DynamoDB, and Lambda across us-east-1 / us-west-2 |

## Architecture

```mermaid
graph TB
    subgraph ARC["Route 53 ARC Cluster"]
        style ARC fill:#FF9900,color:#fff,stroke:#FF9900
        CP_PAY["Payments Control Panel"]
        CP_MAINT["Maintenance Control Panel"]
        RC_PRI["Routing Control\nprimary-us-east-1 ON"]
        RC_FAIL["Routing Control\nfailover-us-west-2 OFF"]
        RC_MAINT["Routing Control\nmaintenance-gate"]
        SR_ASSERT["Safety Rule ASSERTION\nmin 1 cell always ON"]
        SR_GATE["Safety Rule GATING\nmaintenance required to toggle primary"]
        CP_PAY --> RC_PRI
        CP_PAY --> RC_FAIL
        CP_PAY --> SR_ASSERT
        CP_MAINT --> RC_MAINT
        CP_MAINT --> SR_GATE
    end

    subgraph R53["Route 53 DNS"]
        style R53 fill:#1A9C3E,color:#fff,stroke:#1A9C3E
        HC_PRI["Health Check\nprimary — enabled"]
        HC_FAIL["Health Check\nfailover — disabled"]
        DNS_PRI["DNS Record A\nPRIMARY failover policy"]
        DNS_FAIL["DNS Record A\nSECONDARY failover policy"]
        RC_PRI --> HC_PRI
        RC_FAIL --> HC_FAIL
        HC_PRI --> DNS_PRI
        HC_FAIL --> DNS_FAIL
    end

    subgraph Cells["Regional Cells"]
        style Cells fill:#8C4FFF,color:#fff,stroke:#8C4FFF
        CF_PRI["CloudFront Primary\nus-east-1\n100% traffic"]
        CF_FAIL["CloudFront Failover\nus-west-2\n0% traffic — warm standby"]
        DNS_PRI --> CF_PRI
        DNS_FAIL --> CF_FAIL
    end

    subgraph Readiness["Readiness Checks"]
        style Readiness fill:#DD344C,color:#fff,stroke:#DD344C
        RG["Recovery Group"]
        RC_MSK_P["MSK Cluster — primary"]
        RC_MSK_F["MSK Cluster — failover"]
        RC_DDB["DynamoDB Global Table"]
        RC_LMB["Lambda — payment initiator"]
        RG --> RC_MSK_P
        RG --> RC_MSK_F
        RG --> RC_DDB
        RG --> RC_LMB
    end
```

## Running an Example

```bash
cd payment-multi-region-failover
terraform init
terraform apply -var-file="dev.tfvars"
```
