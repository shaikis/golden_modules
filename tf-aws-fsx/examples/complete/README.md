# Complete Example

This example deploys the `tf-aws-fsx` module with a customer-managed KMS key and a single-region FSx layout driven by environment-specific `tfvars` files. Lower environments focus on Windows and ONTAP, while `prod.tfvars` shows Windows, Lustre, ONTAP, and OpenZFS together.

## Architecture

```mermaid
graph TB
    USER["Terraform operator"] --> EX["examples/complete"]
    EX --> KMS["tf-aws-kms<br/>Customer managed key"]
    EX --> MOD["tf-aws-fsx module"]
    KMS -->|kms_key_arn| MOD

    subgraph VPC["Application VPC"]
        WIN["FSx for Windows<br/>Multi-AZ SMB"]
        LUS["FSx for Lustre<br/>Single-AZ HPC"]
        ONT["FSx for ONTAP<br/>Multi-AZ"]
        ZFS["FSx for OpenZFS<br/>Single-AZ or Multi-AZ"]
        SVM["SVM: app-svm"]
        DATA["Volume: /app/data"]
        LOGS["Volume: /app/logs"]
        AD["Active Directory"]
    end

    MOD --> WIN
    MOD --> LUS
    MOD --> ONT
    MOD --> ZFS
    ONT --> SVM
    SVM --> DATA
    SVM --> LOGS
    AD --> WIN
    AD --> SVM

    classDef aws fill:#232F3E,color:#ffffff,stroke:#232F3E;
    classDef accent fill:#FF9900,color:#111111,stroke:#FF9900;
    class KMS,MOD,WIN,LUS,ONT,ZFS,SVM,DATA,LOGS,AD aws;
    class USER,EX accent;
```

## What This Example Shows

- Customer-managed KMS encryption for FSx resources
- FSx for Windows integrated with Active Directory
- FSx for ONTAP with one SVM and multiple volumes
- `fsxadmin` for ONTAP fetched from Secrets Manager rather than hard-coded in Terraform
- Per-environment inputs through `dev.tfvars`, `staging.tfvars`, and `prod.tfvars`

## HA Notes

- Windows: Multi-AZ is supported and shown in the sample tfvars.
- ONTAP: Multi-AZ plus backup and SnapMirror-based DR are supported.
- Lustre: high-performance, but not Multi-AZ in the same way as Windows or ONTAP.
- OpenZFS: deployment-type options exist, but treat it as a separate HA design track from ONTAP replication.

## Run

```bash
terraform init
terraform apply -var-file="dev.tfvars"
```
