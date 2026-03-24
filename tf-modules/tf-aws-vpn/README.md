# tf-aws-vpn

Terraform module for **Site-to-Site VPN** (Customer Gateways + VPN Connections) and **AWS Client VPN** with mutual TLS or SAML/SSO authentication.

## Features

| Feature | Details |
|---------|---------|
| Site-to-Site | IKEv2 tunnels, BGP or static routing, TGW or VGW attachment |
| Client VPN auth | Mutual TLS (certificate) **or** SAML/federated (SSO) |
| Split tunnel | Routes only VPC traffic via VPN |
| Connection logging | CloudWatch log group + stream auto-created |
| Network associations | Multiple subnets supported |
| Authorization rules | Per-group CIDR rules |
| Static VPN routes | Auto-created when `static_routes_only = true` |
| Lifecycle safety | `ignore_changes` on pre-shared keys, `CreatedDate` tag |
| Full tagging | Name, Environment, Project, Owner, CostCenter, ManagedBy |

## Usage

### Switching environments

All example directories contain per-environment `.tfvars` files:

```
dev.tfvars      ← dev/staging/qa share same VPC + TGW (lower envs)
staging.tfvars  ← same VPC/TGW as dev, different env label
prod.tfvars     ← dedicated prod VPC + TGW
```

Run for any environment:

```bash
terraform init
terraform plan  -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

terraform plan  -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

### Site-to-Site VPN (TGW attachment)

```hcl
module "vpn" {
  source      = "git::https://github.com/org/tf-modules//tf-aws-vpn?ref=v1.0.0"
  name        = "platform"
  environment = "prod"

  enable_site_to_site_vpn = true
  transit_gateway_id      = "tgw-0abc123"

  customer_gateways = {
    "dc-primary" = {
      bgp_asn    = 65000
      ip_address = "203.0.113.10"
    }
  }
}
```

### Client VPN (SAML/SSO)

```hcl
module "vpn" {
  source      = "git::https://github.com/org/tf-modules//tf-aws-vpn?ref=v1.0.0"
  name        = "platform"
  environment = "prod"

  enable_client_vpn                         = true
  client_vpn_cidr                           = "10.200.0.0/16"
  client_vpn_vpc_id                         = "vpc-0abc"
  client_vpn_subnet_ids                     = ["subnet-0aaa", "subnet-0bbb"]
  client_vpn_server_cert_arn                = "arn:aws:acm:..."
  client_vpn_saml_provider_arn              = "arn:aws:iam::...:saml-provider/AWSSSO"
  client_vpn_self_service_saml_provider_arn = "arn:aws:iam::...:saml-provider/AWSSSOSelfService"
  client_vpn_split_tunnel                   = true
}
```

## Examples

| Example | Description |
|---------|-------------|
| [basic](./examples/basic) | Site-to-Site VPN via TGW |
| [complete](./examples/complete) | Site-to-Site + Client VPN; all environments via tfvars |

## Variables

### Common

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | — | Resource name prefix |
| `environment` | string | `dev` | Environment label |

### Site-to-Site VPN

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_site_to_site_vpn` | bool | `false` | Enable S2S VPN |
| `transit_gateway_id` | string | `null` | TGW to attach; null → VGW |
| `create_vpn_gateway` | bool | `false` | Create VGW (non-TGW) |
| `customer_gateways` | map(object) | `{}` | CGW + tunnel config per gateway |

### Client VPN

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_client_vpn` | bool | `false` | Enable Client VPN |
| `client_vpn_cidr` | string | `10.200.0.0/16` | VPN client IP pool |
| `client_vpn_server_cert_arn` | string | `null` | ACM server certificate |
| `client_vpn_root_cert_chain_arn` | string | `null` | Mutual TLS root cert |
| `client_vpn_saml_provider_arn` | string | `null` | SAML provider for SSO |
| `client_vpn_split_tunnel` | bool | `true` | Split-tunnel mode |
| `client_vpn_session_timeout_hours` | number | `12` | Max session hours |

## Outputs

| Output | Description |
|--------|-------------|
| `vpn_gateway_id` | VGW ID (when not using TGW) |
| `customer_gateway_ids` | Map of CGW key → ID |
| `vpn_connection_ids` | Map of VPN connection key → ID |
| `vpn_connection_tunnel1_addresses` | Map of key → Tunnel 1 outside IP |
| `client_vpn_endpoint_id` | Client VPN endpoint ID |
| `client_vpn_dns_name` | Client VPN DNS name |
| `client_vpn_log_group_name` | CloudWatch log group name |
