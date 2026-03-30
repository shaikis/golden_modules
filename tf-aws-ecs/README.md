# tf-aws-ecs

Terraform module for AWS ECS clusters, task definitions, and services.

## Features

- ECS cluster with Container Insights enabled by default
- FARGATE, FARGATE_SPOT, and EC2 capacity providers
- Shared task execution IAM role (auto-created)
- Task definitions map with EFS volume support
- Services map with ALB integration, circuit breaker, capacity provider strategies
- `ignore_changes = [desired_count, task_definition]` — Auto Scaling and CI/CD manage these
- `prevent_destroy` on cluster

## Architecture

```mermaid
graph TB
    subgraph Cluster["ECS Cluster (Container Insights)"]
        subgraph Services["ECS Services"]
            SVC1["Service A\n(desired_count · circuit breaker)"]
            SVC2["Service B\n(desired_count · circuit breaker)"]
        end
        subgraph TaskDefs["Task Definitions"]
            TD1["Task Definition A\n(cpu · memory · containers)"]
            TD2["Task Definition B\n(cpu · memory · containers)"]
        end
    end

    subgraph Capacity["Capacity Providers"]
        FG["FARGATE"]
        FGS["FARGATE_SPOT"]
    end

    subgraph IAM["IAM"]
        EXECROLE["Task Execution Role\n(ECR pull · CW logs)"]
        TASKROLE["Task Role\n(app permissions)"]
    end

    ALB["Application Load Balancer\n(target group)"]
    ECR["ECR\n(container images)"]
    CW["CloudWatch Logs\n(/ecs/*)"]
    EFS["EFS Volume\n(optional shared storage)"]
    KMS["KMS Key\n(CloudWatch encryption)"]
    AS["Application Auto Scaling\n(manages desired_count)"]

    ALB --> SVC1
    ALB --> SVC2
    SVC1 --> TD1
    SVC2 --> TD2
    FG --> SVC1
    FGS --> SVC2
    EXECROLE --> TD1
    EXECROLE --> TD2
    TASKROLE --> TD1
    ECR -->|"image pull"| TD1
    ECR -->|"image pull"| TD2
    TD1 --> CW
    TD2 --> CW
    TD1 --> EFS
    KMS --> CW
    AS --> SVC1
    AS --> SVC2

    style Cluster fill:#FF9900,color:#fff,stroke:#FF9900
    style Capacity fill:#232F3E,color:#fff,stroke:#232F3E
    style IAM fill:#DD344C,color:#fff,stroke:#DD344C
    style ALB fill:#8C4FFF,color:#fff,stroke:#8C4FFF
    style CW fill:#FF4F8B,color:#fff,stroke:#FF4F8B
    style KMS fill:#8C4FFF,color:#fff,stroke:#8C4FFF
```

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "ecs" {
  source      = "git::https://github.com/your-org/tf-modules.git//tf-aws-ecs?ref=v1.0.0"
  name        = "platform"
  environment = "prod"
  kms_key_arn = module.kms.key_arn

  task_definitions = {
    api = {
      cpu    = 512
      memory = 1024
      container_definitions = jsonencode([{
        name  = "api"
        image = "123456789.dkr.ecr.us-east-1.amazonaws.com/api:latest"
        portMappings = [{ containerPort = 8080 }]
      }])
    }
  }

  services = {
    api = {
      task_definition_key = "api"
      desired_count       = 2
      network_configuration = {
        subnets         = module.vpc.private_subnet_ids_list
        security_groups = [module.app_sg.security_group_id]
      }
      load_balancers = [{
        target_group_arn = module.alb.target_group_arns["api"]
        container_name   = "api"
        container_port   = 8080
      }]
    }
  }
}
```

