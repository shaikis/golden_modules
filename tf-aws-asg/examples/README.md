# tf-aws-asg Examples

Runnable examples for the [`tf-aws-asg`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [linux](linux/) | Linux Auto Scaling Group with CPU target-tracking scaling, optional scheduled actions, and KMS-encrypted EBS volumes |
| [windows](windows/) | Windows Auto Scaling Group with Active Directory domain-join, mixed-instances policy (on-demand + Spot), CPU and memory target-tracking scaling, and optional scheduled actions |
| [alb-target-groups](alb-target-groups/) | Linux ASG integrated with ALB target groups, ELB health checks, CPU and ALB request-count target-tracking scaling policies |

## Architecture

```mermaid
graph TB
    subgraph Network["VPC / Private Subnets"]
        ASG["Auto Scaling Group"]
        Instance1["EC2 Instance"]
        Instance2["EC2 Instance"]
        InstanceN["EC2 Instance (N)"]
    end

    subgraph ALB["ALB (alb-target-groups example)"]
        LoadBalancer["Application Load Balancer"]
        TargetGroup["Target Group(s)"]
    end

    subgraph Scaling["Scaling Policies"]
        CPUScaling["CPU Target Tracking"]
        MemScaling["Memory Target Tracking\n(Windows)"]
        ALBScaling["ALB Request Count\n(alb-target-groups)"]
        Scheduled["Scheduled Actions\n(optional)"]
    end

    subgraph DomainJoin["AD Domain Join (Windows)"]
        Secret["Secrets Manager\n(domain credentials)"]
        AD["Active Directory"]
    end

    subgraph KMS["AWS KMS (tf-aws-kms)"]
        KMSKey["KMS Key\n(EBS volumes)"]
    end

    KMSKey --> ASG
    ASG --> Instance1
    ASG --> Instance2
    ASG --> InstanceN

    LoadBalancer --> TargetGroup --> ASG
    ASG -- "ELB health check" --> TargetGroup

    CPUScaling --> ASG
    MemScaling --> ASG
    ALBScaling --> ASG
    Scheduled --> ASG

    Secret --> Instance1
    AD --> Instance1
```

## Quick Start

Linux ASG:

```bash
cd linux/
terraform init
terraform apply -var-file="dev.tfvars"
```

Windows ASG with domain join:

```bash
cd windows/
terraform init
terraform apply -var-file="dev.tfvars"
```

ASG with ALB target groups:

```bash
cd alb-target-groups/
terraform init
terraform apply -var-file="dev.tfvars"
```
