# tf-aws-asg-instance-ops

Utility module for per-instance ASG operations. Use alongside `tf-aws-asg`.

## Architecture

```mermaid
graph TB
    subgraph ASG["Auto Scaling Group"]
        I1[Instance i-0abc123\nIN_SERVICE]
        I2[Instance i-0def456\nIN_SERVICE]
        I3[Instance i-0ghi789\nIN_SERVICE]
    end

    subgraph OPS["Instance Operations via SSM Automation"]
        PROTECT[Scale-in Protection\nprotected_instance_ids\nCannot be terminated by scale-in]
        STANDBY[Standby Mode\nstandby_instance_ids\nDetached from LB and health checks]
        DETACH[Detach\ndetach_instance_ids\nRemoved from ASG, still running]
    end

    subgraph LB["Load Balancer"]
        TG[Target Group]
    end

    subgraph PATCH["Maintenance Workflow"]
        SSM[SSM Session\nSSH / patch / debug]
    end

    I1 -->|protected| PROTECT
    I2 -->|maintenance| STANDBY
    I3 -->|remove| DETACH
    PROTECT -.->|stays in LB| TG
    STANDBY -.->|removed from LB during maintenance| TG
    STANDBY --> SSM

    style ASG fill:#FF9900,color:#fff,stroke:#FF9900
    style OPS fill:#232F3E,color:#fff,stroke:#232F3E
    style LB fill:#1A9C3E,color:#fff,stroke:#1A9C3E
    style PATCH fill:#8C4FFF,color:#fff,stroke:#8C4FFF
```

## Operations

| Operation | Variable | Effect | Reversible? |
|-----------|----------|--------|-------------|
| **Scale-in protect** | `protected_instance_ids` | Instance cannot be terminated by scale-in | Yes — remove ID, re-apply |
| **Standby** | `standby_instance_ids` | Instance detached from LB & health checks, stays in ASG | Yes — remove ID, re-apply |
| **Detach** | `detach_instance_ids` | Instance removed from ASG (still running, unmanaged) | Manual — re-attach via console/CLI |

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "asg_ops" {
  source   = "../../tf-aws-asg-instance-ops"
  asg_name = module.asg.asg_name

  # Protect i-0abc123 during a hot patch (no scale-in)
  protected_instance_ids = ["i-0abc123"]

  # Put i-0def456 into standby for maintenance
  standby_instance_ids = ["i-0def456"]
}
```

## Workflow: patch an instance without termination

```bash
# 1. Add to standby via Terraform
echo 'standby_instance_ids = ["i-0abc123"]' >> ops.tfvars
terraform apply -var-file=ops.tfvars

# 2. SSH/SSM in and patch
aws ssm start-session --target i-0abc123

# 3. Return to service
# Remove from standby_instance_ids in tfvars, re-apply
terraform apply -var-file=ops.tfvars
```

