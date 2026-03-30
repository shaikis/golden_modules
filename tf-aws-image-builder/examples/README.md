# tf-aws-image-builder Examples

Runnable examples for the [`tf-aws-image-builder`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [linux](linux/) | EC2 Image Builder pipeline for Linux AMIs with KMS encryption, configurable instance types, custom components, scheduled pipeline, and multi-region distribution |
| [windows](windows/) | EC2 Image Builder pipeline for Windows AMIs with KMS encryption, domain-join support, AMI launch permissions, and mixed-instance distribution |
| [packer-ansible](packer-ansible/) | Hybrid approach — EC2 Image Builder pipeline that downloads Packer templates and Ansible playbooks from S3 and runs them inside the build instance; supports both Linux and Windows platforms |

## Architecture

```mermaid
graph TB
    subgraph Build["EC2 Image Builder"]
        Recipe["Image Recipe\n(base AMI + components)"]
        Pipeline["Pipeline\n(scheduled or on-demand)"]
        BuildInstance["Build Instance\n(EC2 — Linux or Windows)"]
        DistConfig["Distribution Config\n(multi-region AMI sharing)"]
    end

    subgraph Components
        CustomComp["Custom Components\n(inline YAML)"]
        ManagedComp["AWS Managed Components"]
        AnsibleComp["Ansible Bootstrap Component\n(packer-ansible only)"]
    end

    subgraph Artifacts["S3 Artifacts (packer-ansible)"]
        PackerTmpl["Packer Template\n(.pkr.hcl)"]
        AnsiblePB["Ansible Playbooks\n(site.yml, requirements.yml)"]
    end

    subgraph KMS["AWS KMS (tf-aws-kms)"]
        KMSKey["KMS Key\n(AMI + snapshot encryption)"]
    end

    subgraph Output
        AMI["Golden AMI\n(distributed to target regions)"]
    end

    KMSKey --> Recipe
    CustomComp --> Recipe
    ManagedComp --> Recipe
    Recipe --> Pipeline --> BuildInstance

    PackerTmpl --> AnsibleComp
    AnsiblePB --> AnsibleComp
    AnsibleComp --> BuildInstance

    BuildInstance --> DistConfig --> AMI
```

## Quick Start

Linux AMI:

```bash
cd linux/
terraform init
terraform apply -var-file="dev.tfvars"
```

Windows AMI:

```bash
cd windows/
terraform init
terraform apply -var-file="dev.tfvars"
```

Packer + Ansible pipeline:

```bash
cd packer-ansible/
terraform init
terraform apply -var-file="dev.tfvars"
```
