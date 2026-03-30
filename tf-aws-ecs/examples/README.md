# tf-aws-ecs Examples

Runnable examples for the [`tf-aws-ecs`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal configuration — single ECS cluster with one task definition (web container) and one Fargate service using CloudWatch Logs |
| [complete](complete/) | Full configuration with Fargate + Fargate Spot capacity provider strategy, two services (API and worker), EFS shared volume, ECS Exec enabled, and mixed capacity provider weights |

## Architecture

```mermaid
graph TB
    subgraph Complete["Complete Example"]
        EFS["EFS File System\n(shared-data volume)"]
        Cluster["ECS Cluster\n(Fargate + Fargate Spot)"]
        subgraph Services["Services"]
            API["api service\n(2 tasks, FARGATE+SPOT mix)"]
            Worker["worker service\n(1 task, FARGATE_SPOT)"]
        end
        subgraph Logs["CloudWatch Logs"]
            LogAPI["/ecs/name-api"]
            LogWorker["/ecs/name-worker"]
        end
    end

    EFS -->|efs_volume_configuration| API
    Cluster --> Services
    API --> LogAPI
    Worker --> LogWorker
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
