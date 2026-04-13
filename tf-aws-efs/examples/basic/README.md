# basic

Minimal EFS example for a single source file system with optional one-to-one replication.

## Architecture

```mermaid
flowchart TB
    VPC["VPC"] --> SUB["Private subnets"]
    SUB --> MT["EFS mount targets"]
    SG["Managed EFS security group<br/>NFS 2049 only"] --> MT
    EFS["Primary EFS file system"] --> MT
    APP["EC2 / ECS / EKS clients"] --> MT
    EFS --> REP["Optional 1:1 replication"]
    REP --> DEST["Destination EFS<br/>same-region or cross-region"]
```

## Scenario Covered

- `1:1` replication
- Regional EFS for multi-AZ when `availability_zone_name = null`
- One Zone EFS for single-AZ when `availability_zone_name` is set
- same-region replication if destination stays in the same Region
- cross-region replication if destination region differs

## Not Covered

- `1:many` replication is not supported by Amazon EFS
- `many:1` replication is not supported by Amazon EFS

## Run

```bash
terraform init
terraform apply -var-file="dev.tfvars"
```
