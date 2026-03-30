# tf-aws-alb Examples

Runnable examples for the [`tf-aws-alb`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal ALB configuration — HTTP/HTTPS listeners with instance target groups using variable-driven input |
| [asg-instances](asg-instances/) | ALB fronting an Auto Scaling Group — HTTP→HTTPS redirect, path-based routing to web and API target groups, ASG with CPU and request-count target tracking |
| [ip-targets](ip-targets/) | ALB with IP-type target groups — ECS Fargate containers, on-premises servers via VPN/Direct Connect, and cross-VPC peered IPs on a single load balancer |
| [lambda-targets](lambda-targets/) | ALB routing to Lambda microservices — three functions (users, orders, products) with path-based rules and CORS preflight handling |
| [nlb-basic](nlb-basic/) | Network Load Balancer (NLB) with a single TCP listener forwarding to EC2 instance targets |

## Architecture

```mermaid
graph TB
    Internet((Internet)) --> ALB

    subgraph ALB["Application Load Balancer"]
        HTTP80["Listener :80\nHTTP → redirect HTTPS"]
        HTTPS443["Listener :443\nHTTPS"]
        Rules["Listener Rules\n(path-based)"]
    end

    HTTPS443 --> Rules

    subgraph Targets["Target Groups"]
        TG_Web["web:80\ninstance / ASG"]
        TG_API["api:8080\ninstance / ASG"]
        TG_Fargate["fargate:8080\nip / ECS Fargate"]
        TG_OnPrem["onprem:80\nip / VPN servers"]
        TG_Lambda["lambda\nusers · orders · products"]
    end

    Rules -->|"default / /*"| TG_Web
    Rules -->|"/api/*"| TG_API
    Rules -->|"/api/* (ip-targets)"| TG_Fargate
    Rules -->|"/legacy/*"| TG_OnPrem
    Rules -->|"/api/users·orders·products"| TG_Lambda

    subgraph NLB["Network Load Balancer (nlb-basic)"]
        TCP["Listener TCP\nport-based forward"]
        TG_TCP["tcp_app\ninstance"]
    end
    TCP --> TG_TCP
```

## Quick Start

```bash
cd basic/
terraform init
terraform apply -var-file="dev.tfvars"
```
