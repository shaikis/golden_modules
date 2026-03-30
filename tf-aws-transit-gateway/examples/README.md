# tf-aws-transit-gateway Examples

Runnable examples for the [`tf-aws-transit-gateway`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — Transit Gateway with VPC attachments using default route table association and propagation |
| [complete](complete/) | Full configuration with custom route tables, static routes, VPC attachments, ECMP support, and AWS RAM sharing to other accounts or AWS Organizations |

## Architecture

```mermaid
graph TB
    subgraph TGW["Transit Gateway"]
        DefaultRT["Default Route Table\n(basic)"]
        SpokeRT["Spoke Route Table\n(complete)"]
        SharedRT["Shared Services RT\n(complete)"]
    end

    subgraph VPCs["VPC Attachments"]
        VPC1["VPC A\n(App)"]
        VPC2["VPC B\n(Shared Services)"]
        VPC3["VPC C\n(Dev)"]
    end

    RAM["AWS RAM Share\n(complete only)"]
    OtherAccount["Other AWS Account\n/ AWS Organization"]

    VPC1 -->|"Attachment"| TGW
    VPC2 -->|"Attachment"| TGW
    VPC3 -->|"Attachment"| TGW
    TGW --> SpokeRT
    TGW --> SharedRT
    RAM --> OtherAccount
    TGW --> RAM
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
