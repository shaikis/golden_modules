# tf-aws-data-e-batch

Production-grade Terraform module for AWS Batch. Supports managed and unmanaged compute environments (EC2, Spot, Fargate, Fargate Spot, EKS), job queues with priority ordering, job definitions (container, multi-node), fair-share scheduling policies, CloudWatch alarms, and full IAM role management.

## Features

- Map-driven `for_each` on all primary resources (no `count`)
- Choice-based: every advanced feature is opt-in via boolean gate defaulting to `false`
- BYO foundational resources: supply `role_arn` from external IAM module
- `create_iam_role = true` by default for zero-config getting started
- Compute environments: Fargate, Fargate Spot, EC2, EC2 Spot, EKS-backed
- Job queues: priority-based ordering, fair-share scheduling, job state time limit actions
- Job definitions: container, GPU, with auto-built `container_properties` JSON or override
- Fair-share scheduling policies: per-share-identifier weight distributions
- CloudWatch alarms: pending jobs, runnable count, failed jobs, success rate
- All files pass `terraform fmt -check`

## Usage

### Minimal — Fargate Spot + one queue + one job

```hcl
module "batch" {
  source = "git::https://github.com/your-org/tf-aws-data-e-batch.git"

  compute_environments = {
    "fargate-spot" = {
      type               = "MANAGED"
      compute_type       = "FARGATE_SPOT"
      max_vcpus          = 256
      subnet_ids         = ["subnet-0abc123"]
      security_group_ids = ["sg-0abc123"]
    }
  }

  job_queues = {
    "default" = {
      priority                 = 10
      compute_environment_keys = ["fargate-spot"]
    }
  }

  job_definitions = {
    "my-etl-job" = {
      image  = "123456789012.dkr.ecr.us-east-1.amazonaws.com/etl:latest"
      vcpus  = 1
      memory = 2048
    }
  }
}
```

### BYO service role

```hcl
module "batch" {
  source = "git::https://github.com/your-org/tf-aws-data-e-batch.git"

  create_iam_role = false
  role_arn        = module.iam.batch_service_role_arn

  compute_environments = { ... }
  job_queues           = { ... }
  job_definitions      = { ... }
}
```

## Scenarios

### 1. Scheduled ETL Jobs

Run nightly data pipeline jobs on Fargate Spot for maximum cost efficiency.

```hcl
compute_environments = {
  "fargate-spot-etl" = {
    compute_type       = "FARGATE_SPOT"
    max_vcpus          = 256
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.batch_sg_id]
  }
}

job_definitions = {
  "nightly-etl" = {
    image           = "${var.ecr_repo}/etl-worker:latest"
    vcpus           = 2
    memory          = 4096
    command         = ["python3", "-m", "etl.nightly"]
    retry_attempts  = 3
    timeout_seconds = 7200
    environment = {
      RUN_DATE = "#{dateTimeNow('YYYY-MM-DD')}"
    }
  }
}
```

### 2. ML Training Pipeline

GPU-accelerated ML training on EC2 Spot instances (p3/g4dn) for up to 70% cost savings.

```hcl
compute_environments = {
  "gpu-spot-ce" = {
    compute_type        = "SPOT"
    instance_types      = ["p3.2xlarge", "g4dn.xlarge", "g4dn.2xlarge"]
    max_vcpus           = 128
    spot_bid_percentage = 70
    allocation_strategy = "SPOT_PRICE_CAPACITY_OPTIMIZED"
    subnet_ids          = var.private_subnet_ids
    security_group_ids  = [var.batch_sg_id]
  }
}

job_definitions = {
  "ml-training" = {
    platform_capabilities = ["EC2"]
    image                 = "${var.ecr_repo}/ml-trainer:latest"
    vcpus                 = 8
    memory                = 61440
    gpu_count             = 1
    timeout_seconds       = 86400
    retry_attempts        = 1
  }
}
```

### 3. Data Quality Validation

Lightweight Fargate jobs for data quality checks that run after each ETL load.

```hcl
job_definitions = {
  "dq-validator" = {
    image           = "${var.ecr_repo}/dq-checker:latest"
    vcpus           = 1
    memory          = 2048
    command         = ["python3", "-m", "dq.validate"]
    retry_attempts  = 2
    timeout_seconds = 1800
    environment = {
      DQ_CONFIG  = "s3://config-bucket/dq_rules.yaml"
      FAIL_FAST  = "true"
    }
  }
}
```

### 4. Priority Queues for SLA Tiers

Route jobs to different queues based on SLA requirements. High-priority jobs use On-Demand compute; low-priority jobs use Spot.

```hcl
job_queues = {
  "sla-critical" = {
    priority                 = 100
    compute_environment_keys = ["ec2-ondemand-ce", "fargate-spot-ce"]
  }
  "best-effort" = {
    priority                 = 10
    compute_environment_keys = ["fargate-spot-ce"]
  }
}
```

### 5. Fargate Spot for Serverless Containers

Fully serverless batch workloads with no EC2 instance management. AWS manages the underlying compute.

```hcl
compute_environments = {
  "serverless-spot" = {
    type         = "MANAGED"
    compute_type = "FARGATE_SPOT"
    max_vcpus    = 512
    subnet_ids   = var.private_subnet_ids
    security_group_ids = [var.batch_sg_id]
  }
}
```

### 6. Fair-Share Scheduling

Prevent one team from monopolizing compute with weighted fair-share distribution.

```hcl
create_scheduling_policies = true

scheduling_policies = {
  "team-fair-share" = {
    compute_reservation = 20
    share_decay_seconds = 3600
    share_distributions = [
      { share_identifier = "team-a", weight_factor = 3.0 },
      { share_identifier = "team-b", weight_factor = 2.0 },
      { share_identifier = "team-c", weight_factor = 1.0 }
    ]
  }
}

job_queues = {
  "shared-queue" = {
    priority                 = 10
    compute_environment_keys = ["fargate-spot-ce"]
    scheduling_policy_key    = "team-fair-share"
  }
}
```

### 7. Spot-Based Cost Optimization

Multi-instance-type EC2 Spot compute environment for maximum Spot availability and savings.

```hcl
compute_environments = {
  "cost-optimized-spot" = {
    compute_type        = "SPOT"
    instance_types      = ["m5.2xlarge", "m5.4xlarge", "m5a.2xlarge", "m5a.4xlarge", "m6i.2xlarge"]
    max_vcpus           = 512
    spot_bid_percentage = 60
    allocation_strategy = "SPOT_PRICE_CAPACITY_OPTIMIZED"
    subnet_ids          = var.private_subnet_ids
    security_group_ids  = [var.batch_sg_id]
  }
}
```

### 8. Array Jobs for Parallelism

Submit array jobs to process thousands of independent tasks in parallel (e.g., process one S3 file per task).

The module creates the job definition; submit the array job via CLI or Step Functions:
```bash
aws batch submit-job \
  --job-name "process-files-array" \
  --job-queue "normal-queue" \
  --job-definition "etl-container-job" \
  --array-properties size=500
```

### 9. Job Chaining with Step Functions

Orchestrate multi-stage pipelines — ETL → data quality → ML training → report generation — using AWS Step Functions with Batch job state machine tasks.

The module outputs `job_queue_arns` and `job_definition_arns` for use in Step Functions state machine definitions.

### 10. GPU Model Training

Deploy GPU compute environments for deep learning model training, with Spot instances for cost optimization.

```hcl
compute_environments = {
  "gpu-training-ce" = {
    compute_type        = "SPOT"
    instance_types      = ["p3.2xlarge", "p3.8xlarge", "p4d.24xlarge"]
    max_vcpus           = 256
    spot_bid_percentage = 80
    allocation_strategy = "SPOT_PRICE_CAPACITY_OPTIMIZED"
    subnet_ids          = var.private_subnet_ids
    security_group_ids  = [var.batch_sg_id]
  }
}

job_definitions = {
  "deep-learning-train" = {
    platform_capabilities = ["EC2"]
    image                 = "${var.ecr_repo}/pytorch-trainer:2.0-gpu"
    vcpus                 = 32
    memory                = 245760
    gpu_count             = 8
    timeout_seconds       = 172800  # 48 hours
    retry_attempts        = 1
  }
}
```

### 11. Multi-Node Parallel Jobs

Run tightly coupled distributed workloads (like MPI jobs) across multiple EC2 instances.

Use `container_properties_override` with `node_properties` JSON to define multi-node configurations when Batch's multi-node parallel job type is needed.

### 12. Monitoring Failed Jobs

Enable alarms with SNS to get immediate notification when batch jobs fail.

```hcl
create_alarms       = true
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:batch-alerts"

alarm_thresholds = {
  pending_job_count_max = 50
  failed_job_count_max  = 5
}
```

## Module Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `create_iam_role` | bool | `true` | Create Batch service role, EC2 instance role, ECS task execution role, job role, Spot fleet role |
| `create_scheduling_policies` | bool | `false` | Create fair-share scheduling policies |
| `create_alarms` | bool | `false` | Create CloudWatch alarms |
| `role_arn` | string | `null` | Existing Batch service role ARN (when `create_iam_role = false`) |
| `alarm_sns_topic_arn` | string | `null` | SNS topic ARN for alarm notifications |
| `compute_environments` | map(object) | `{}` | Map of compute environment configurations |
| `job_queues` | map(object) | `{}` | Map of job queue configurations |
| `job_definitions` | map(object) | `{}` | Map of job definition configurations |
| `scheduling_policies` | map(object) | `{}` | Map of fair-share scheduling policy configurations |
| `alarm_thresholds` | object | `{}` | Thresholds for CloudWatch alarms |
| `tags` | map(string) | `{}` | Default tags applied to all resources |

## Module Outputs

| Name | Description |
|------|-------------|
| `compute_environment_arns` | Map of compute environment name to ARN |
| `job_queue_arns` | Map of job queue name to ARN |
| `job_definition_arns` | Map of job definition name to ARN |
| `scheduling_policy_arns` | Map of scheduling policy name to ARN |
| `batch_service_role_arn` | ARN of the Batch service IAM role |
| `ec2_instance_profile_arn` | ARN of the EC2 instance profile |
| `ecs_task_execution_role_arn` | ARN of the ECS task execution IAM role |
| `job_role_arn` | ARN of the Batch job IAM role |
| `spot_fleet_role_arn` | ARN of the Spot fleet IAM role |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |
