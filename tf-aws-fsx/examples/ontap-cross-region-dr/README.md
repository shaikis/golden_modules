# ONTAP DR Example

This example deploys primary and DR FSx for ONTAP environments and layers AWS Backup, SnapMirror, and Route 53 failover on top. The default shape is cross-region DR, and the same example can also be adapted for same-region replication by placing both clusters in one region and switching to `sync` or `strictSync`.

## Architecture

```mermaid
graph LR
    OP["Terraform operator"] --> PRI_MOD["module.fsx_primary"]
    OP --> DR_MOD["module.fsx_dr"]

    subgraph PRIMARY["Primary Region"]
        KMS1["KMS key"]
        PFS["FSx for ONTAP<br/>MULTI_AZ_1"]
        PSVM["SVM: app-svm"]
        PDATA["Volume: data"]
        PLOGS["Volume: logs"]
        PARCH["Volume: archive"]
        BACKUP["AWS Backup vault"]
        HC["Route 53 health check"]
    end

    subgraph SECONDARY["DR Region"]
        KMS2["KMS key"]
        DFS["FSx for ONTAP<br/>MULTI_AZ_1"]
        DSVM["SVM: app-svm-dr"]
        DRVAULT["DR backup vault"]
    end

    DNS["Route 53 failover CNAME"]
    SM["SnapMirror replication"]

    KMS1 --> PRI_MOD
    KMS2 --> DR_MOD
    PRI_MOD --> PFS
    DR_MOD --> DFS
    PFS --> PSVM
    PSVM --> PDATA
    PSVM --> PLOGS
    PSVM --> PARCH
    DFS --> DSVM
    PFS --> BACKUP
    BACKUP -->|cross-region copy| DRVAULT
    PSVM --> SM --> DSVM
    PFS --> HC
    HC --> DNS
    DFS --> DNS

    classDef aws fill:#232F3E,color:#ffffff,stroke:#232F3E;
    classDef primary fill:#FF9900,color:#111111,stroke:#FF9900;
    classDef secondary fill:#DD344C,color:#ffffff,stroke:#DD344C;
    class OP,DNS,SM aws;
    class KMS1,PFS,PSVM,PDATA,PLOGS,PARCH,BACKUP,HC,PRI_MOD primary;
    class KMS2,DFS,DSVM,DRVAULT,DR_MOD secondary;
```

## What This Example Shows

- Secrets Manager-backed `fsxadmin` credentials for both FSx ONTAP clusters and SnapMirror sessions
- Multi-volume replication for `data`, `logs`, and `archive`
- Volume-level and SVM-level replication
- AWS Backup cross-region copy into a DR vault
- Route 53 failover records for client cutover
- Same-region replication option by setting `primary_region` and `dr_region` to the same value and using `replication_mode = "sync"` or `"strictSync"`

## HA Notes

- FSx for ONTAP supports `MULTI_AZ_1` and is the best fit here for HA plus replication-driven DR.
- FSx for Windows also supports Multi-AZ, but this example is focused on ONTAP replication patterns.
- FSx for Lustre is not a Multi-AZ service; design HA around workload retry and data rehydration.
- FSx for OpenZFS has deployment-type options in the module, but ONTAP-style SnapMirror replication is not implemented for it here.

## Run

```bash
terraform init
terraform apply -target=module.kms_primary -target=module.kms_dr -target=module.fsx_primary -target=module.fsx_dr
terraform apply
```
