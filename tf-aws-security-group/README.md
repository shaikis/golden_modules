# tf-aws-security-group

Terraform module for AWS Security Groups with individually managed rules.

## Architecture

```mermaid
graph LR
    subgraph VPC["VPC (vpc_id)"]
        style VPC fill:#232F3E,color:#fff,stroke:#232F3E

        subgraph SG["Security Group\naws_security_group"]
            style SG fill:#FF9900,color:#fff,stroke:#FF9900
            SGR["Security Group Resource\nname, description, vpc_id"]
        end

        subgraph Ingress["Ingress Rules\n(aws_vpc_security_group_ingress_rule)"]
            style Ingress fill:#1A9C3E,color:#fff,stroke:#1A9C3E
            IR1["Rule: https_from_alb\nport 443 from sg-alb"]
            IR2["Rule: http_internal\nport 80 from CIDR"]
            IR3["Rule: ssh_bastion\nport 22 from sg-bastion"]
        end

        subgraph Egress["Egress Rules\n(aws_vpc_security_group_egress_rule)"]
            style Egress fill:#8C4FFF,color:#fff,stroke:#8C4FFF
            ER1["Rule: allow_all_outbound\n0.0.0.0/0 all ports"]
        end

        subgraph RefSGs["Referenced Security Groups\n(sg-to-sg rules)"]
            style RefSGs fill:#DD344C,color:#fff,stroke:#DD344C
            ALB_SG["ALB Security Group\n(source_sg_ids)"]
            BST_SG["Bastion Security Group\n(source_sg_ids)"]
        end
    end

    ALB_SG -->|"source_sg_id"| IR1
    BST_SG -->|"source_sg_id"| IR3
    SGR --> IR1
    SGR --> IR2
    SGR --> IR3
    SGR --> ER1
```

## Features

- Security group with per-rule resources (`aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`)
- Rule map keyed by name → stable lifecycle, no index-based replacements
- `create_before_destroy = true` for zero-downtime rule changes
- Default: deny all inbound, allow all outbound
- Full tagging

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "sg" {
  source      = "git::https://github.com/your-org/tf-modules.git//tf-aws-security-group?ref=v1.0.0"

  name        = "app-server"
  vpc_id      = module.vpc.vpc_id
  environment = "prod"

  ingress_rules = {
    https_from_alb = {
      from_port     = 443
      to_port       = 443
      protocol      = "tcp"
      source_sg_ids = [module.alb_sg.security_group_id]
      description   = "HTTPS from ALB"
    }
  }
}
```
