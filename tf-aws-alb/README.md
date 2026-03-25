# tf-aws-alb

Terraform module for AWS Application/Network Load Balancers.

## Features

- ALB or NLB
- Target groups with health checks and stickiness (`for_each` — stable)
- Listeners: HTTP, HTTPS, redirect, fixed-response
- Multiple certificates per HTTPS listener
- Drop invalid header fields (XSS protection)
- Deletion protection enabled by default
- Access logs to S3
- WAF v2 association
- `prevent_destroy` lifecycle guard

## Security Controls

| Control | Default |
|---------|---------|
| Deletion protection | `true` |
| Drop invalid headers | `true` |
| TLS 1.3 SSL policy | `ELBSecurityPolicy-TLS13-1-2-2021-06` |
| WAF | Optional |

## Usage

```hcl
module "alb" {
  source      = "git::https://github.com/your-org/tf-modules.git//tf-aws-alb?ref=v1.0.0"
  name        = "app"
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.public_subnet_ids_list
  security_groups = [module.alb_sg.security_group_id]

  target_groups = {
    app = { port = 8080; target_type = "ip" }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = { type = "redirect" }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:..."
      default_action  = { type = "forward"; target_group_key = "app" }
    }
  }
}
```
