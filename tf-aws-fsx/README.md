# tf-aws-fsx

Terraform module for Amazon FSx covering Windows File Server, NetApp ONTAP, and Lustre deployments.

---

## Architecture

```mermaid
graph TB
    subgraph PRIMARY["Primary Region"]
        subgraph ONTAP_P["FSx for NetApp ONTAP"]
            FS_P["File system<br/>Multi-AZ"]
            SVM_P["Storage Virtual Machine"]
            VOL_P["ONTAP volumes"]
        end
        subgraph WIN["FSx for Windows"]
            WIN_FS["Windows file server<br/>AD joined"]
        end
        subgraph LUS["FSx for Lustre"]
            LUS_FS["Lustre file system"]
            S3_LINK["S3 data repository"]
        end
        AD["AWS Managed AD or self-managed AD"]
    end

    subgraph DR["DR Region"]
        subgraph ONTAP_DR["FSx for NetApp ONTAP DR"]
            SVM_DR["DR SVM"]
            VOL_DR["Replicated volumes"]
        end
    end

    SM["SnapMirror replication"]

    AD --> WIN_FS
    AD --> SVM_P
    FS_P --> SVM_P
    SVM_P --> VOL_P
    LUS_FS <--> S3_LINK
    SVM_P --> SM --> SVM_DR
    SVM_DR --> VOL_DR

    style PRIMARY fill:#FF9900,color:#111111,stroke:#FF9900
    style DR fill:#DD344C,color:#ffffff,stroke:#DD344C
    style ONTAP_P fill:#232F3E,color:#ffffff,stroke:#232F3E
    style ONTAP_DR fill:#232F3E,color:#ffffff,stroke:#232F3E
    style SM fill:#5B8DEF,color:#ffffff,stroke:#5B8DEF
```

---

## Features

- FSx for Windows with Active Directory integration
- FSx for NetApp ONTAP with SVMs, volumes, and SnapMirror replication
- FSx for Lustre for high-performance workloads and S3-linked storage
- KMS encryption support across supported file systems
- Multi-AZ deployment support for Windows and ONTAP

## Security Controls

| Control | Implementation |
|---------|---------------|
| Encryption at rest | `kms_key_arn` |
| AD authentication | `active_directory_id` and SVM AD settings |
| Network isolation | Explicit subnet and security group inputs |
| Backup retention | Configurable automatic backup retention settings |

## Versioning

Use explicit git tags such as `?ref=v1.0.0` to pin deployments.

## Usage - FSx for ONTAP with SnapMirror

```hcl
module "fsx" {
  source = "git::https://github.com/your-org/golden_modules.git//tf-aws-fsx?ref=v1.0.0"

  kms_key_arn = module.kms.key_arn

  ontap = {
    storage_capacity    = 1024
    deployment_type     = "MULTI_AZ_1"
    throughput_capacity = 512
    subnet_ids          = module.vpc.private_subnet_ids
  }
}
```

## FSx File System Comparison

| Feature | Windows | ONTAP | Lustre |
|---------|---------|-------|--------|
| Protocol | SMB / NFS | NFS / SMB / iSCSI | Lustre |
| AD integration | Native | Via SVM | No |
| Multi-AZ | Yes | Yes | No |
| DR replication | DFS | SnapMirror | S3 export pattern |
| Use case | Windows workloads | Enterprise NAS | HPC / ML |

## Examples

- [Complete example](examples/complete/)
- [ONTAP SnapMirror DR](examples/ontap-cross-region-dr/)
