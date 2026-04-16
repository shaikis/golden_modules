# tf-aws-ec2

Terraform module for AWS EC2 instances with security-hardened defaults.

## Features

- On-demand or Spot instance
- Auto-selects latest Amazon Linux 2023 AMI if no AMI specified
- IMDSv2 required by default (prevents SSRF metadata attacks)
- Encrypted root + data volumes by default (KMS configurable)
- `disable_api_termination = true` by default (termination protection)
- Detailed CloudWatch monitoring enabled by default
- Elastic IP support
- Multiple EBS volumes via `ebs_volumes` map
- CPU options and credit specification

## Security Controls

| Control | Default |
|---------|---------|
| IMDSv2 required | `http_tokens = "required"` |
| Root volume encrypted | `true` |
| Termination protection | `disable_api_termination = true` |
| No public IP | `associate_public_ip_address = false` |
| `lifecycle.prevent_destroy` | `true` |
| `lifecycle.ignore_changes [ami]` | AMI drift won't cause replacement |

## Architecture

```mermaid
graph TB
    subgraph VPC["VPC / Subnet"]
        EC2["EC2 Instance\n(On-Demand or Spot)"]
        SG["Security Group"]
        EIP["Elastic IP\n(optional)"]
    end

    subgraph Storage["EBS Storage"]
        ROOT["Root Volume\n(encrypted · KMS)"]
        DATA["Additional EBS Volumes\n(encrypted · KMS)"]
    end

    subgraph IAM["IAM"]
        ROLE["IAM Role"]
        PROFILE["Instance Profile"]
    end

    subgraph Metadata["Instance Metadata"]
        IMDS["IMDSv2\n(http_tokens=required)"]
    end

    KMS["KMS Key\n(EBS encryption)"]
    CW["CloudWatch\n(detailed monitoring)"]
    SSM["SSM Parameter\n(AMI lookup)"]

    SSM -->|"latest AMI"| EC2
    PROFILE --> EC2
    ROLE --> PROFILE
    SG --> EC2
    EIP --> EC2
    EC2 --> ROOT
    EC2 --> DATA
    KMS --> ROOT
    KMS --> DATA
    EC2 --> IMDS
    EC2 --> CW

    style VPC fill:#FF9900,color:#fff,stroke:#FF9900
    style Storage fill:#3F8624,color:#fff,stroke:#3F8624
    style IAM fill:#DD344C,color:#fff,stroke:#DD344C
    style Metadata fill:#1A73E8,color:#fff,stroke:#1A73E8
    style KMS fill:#8C4FFF,color:#fff,stroke:#8C4FFF
    style CW fill:#FF4F8B,color:#fff,stroke:#FF4F8B
```

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "ec2_fleet" {
  source = "git::https://github.com/shaikis/golden_modules.git//tf-aws-ec2?ref=main"

  name_prefix = "app"
  environment = "dev"

  instances = {
    app01 = {
      instance_type          = "t3.medium"
      subnet_id              = "subnet-xxxx"
      vpc_security_group_ids = ["sg-xxxx"]
      create_eip             = true
    }

    worker01 = {
      use_spot               = true
      spot_price             = "0.08"
      instance_type          = "t3.large"
      subnet_id              = "subnet-yyyy"
      vpc_security_group_ids = ["sg-yyyy"]
    }
  }
}
```

## Examples

- [Basic](examples/basic/)
- [Complete](examples/complete/)

