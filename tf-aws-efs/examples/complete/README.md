# complete

Production-style EFS example with access points, lifecycle management, backup, and richer one-to-one replication options.

## Architecture

```mermaid
flowchart TB
    KMS["Customer-managed KMS key"] --> EFS["Primary EFS file system"]
    EFS --> MT["Mount targets across AZs"]
    SG["Managed EFS security group"] --> MT
    AP1["Access point: /app"] --> EFS
    AP2["Access point: /logs"] --> EFS
    AP3["Access point: /config"] --> EFS
    BACKUP["AWS Backup policy"] --> EFS
    LIFE["Lifecycle policies<br/>IA and recall"] --> EFS
    APP["Application workloads"] --> MT
    EFS --> REP["1:1 DR replication"]
    REP --> DR["Destination EFS in DR region"]
```

## Scenario Covered

- production-oriented `1:1` replication
- Regional EFS for multi-AZ production layouts when `availability_zone_name = null`
- One Zone EFS for single-AZ deployments when `availability_zone_name` is set
- cross-region DR replication
- same module with mount, backup, lifecycle, and access-point configuration

## Not Covered

- `1:many` replication is not supported by Amazon EFS
- `many:1` replication is not supported by Amazon EFS
- cross-account role-based replication is not first-class in this Terraform module because of current provider schema limits

## Run

```bash
terraform init
terraform apply -var-file="prod.tfvars"
```
