# tf-aws-acm

Terraform module that provisions an **AWS Certificate Manager (ACM) SSL/TLS certificate** with fully automated **Route 53 DNS validation**. The module creates the certificate, writes the required CNAME records to your hosted zone, and optionally blocks until the certificate reaches `ISSUED` status — zero manual steps required.

---

## Architecture

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │                         AWS Account                                  │
  │                                                                      │
  │   ┌─────────────────────┐       ┌──────────────────────────────────┐ │
  │   │   Route 53 Zone     │       │     ACM Certificate              │ │
  │   │                     │       │                                  │ │
  │   │  CNAME record  ─────┼──────►│  domain_name: example.com        │ │
  │   │  (validation)       │       │  SANs:        *.example.com      │ │
  │   │                     │       │  status:      ISSUED             │ │
  │   └─────────────────────┘       └──────────────┬───────────────────┘ │
  │                                                │ certificate_arn      │
  │                                                ▼                      │
  │                                 ┌──────────────────────────────────┐ │
  │                                 │   ALB HTTPS Listener  (port 443) │ │
  │                                 │   CloudFront Distribution        │ │
  │                                 └──────────────────────────────────┘ │
  └──────────────────────────────────────────────────────────────────────┘

  Flow:
  1. Terraform requests certificate from ACM
  2. ACM returns CNAME name/value pairs (domain_validation_options)
  3. Module writes CNAME records to the Route 53 hosted zone
  4. ACM polls DNS, finds the CNAME records, and issues the certificate
  5. aws_acm_certificate_validation waiter confirms ISSUED status
  6. certificate_arn is ready for use in ALB listeners / CloudFront
```

---

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

### 1. Single domain with DNS validation (most common)

```hcl
module "acm" {
  source  = "../tf-aws-acm"

  name        = "my-app"
  environment = "prod"
  domain_name = "example.com"

  route53_zone_id     = "Z1D633PJN98FT9"   # your hosted zone ID
  validation_method   = "DNS"
  wait_for_validation = true

  tags = {
    Project = "my-app"
    Owner   = "platform-team"
  }
}

# Pass the ARN to your ALB module
module "alb" {
  source                   = "../tf-aws-alb"
  # ...
  listener_certificate_arn = module.acm.certificate_arn
}
```

---

### 2. Wildcard certificate (`*.example.com` + bare domain as SAN)

```hcl
module "acm_wildcard" {
  source  = "../tf-aws-acm"

  name        = "wildcard"
  environment = "prod"
  domain_name = "*.example.com"

  subject_alternative_names = [
    "example.com",      # bare domain — browsers need this too
  ]

  route53_zone_id     = "Z1D633PJN98FT9"
  validation_method   = "DNS"
  wait_for_validation = true

  tags = {
    Project = "platform"
  }
}
```

> A wildcard cert (`*.example.com`) does **not** automatically cover the bare apex (`example.com`). Always add the bare domain as a SAN.

---

### 3. Multi-domain certificate with SANs

```hcl
module "acm_multi" {
  source  = "../tf-aws-acm"

  name        = "multi-domain"
  environment = "prod"
  domain_name = "example.com"

  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "admin.example.com",
    "app.example.com",
  ]

  route53_zone_id     = "Z1D633PJN98FT9"
  validation_method   = "DNS"
  wait_for_validation = true
  key_algorithm       = "EC_prime256v1"   # smaller + faster than RSA_2048

  tags = {
    Project = "platform"
  }
}
```

---

### 4. Email validation (no Route 53)

Use this when you do not manage the DNS zone in Route 53. AWS sends a validation email to the domain's WHOIS contacts and standard addresses (`admin@`, `postmaster@`, etc.).

```hcl
module "acm_email" {
  source  = "../tf-aws-acm"

  name              = "external-domain"
  environment       = "prod"
  domain_name       = "partner-domain.com"
  validation_method = "EMAIL"

  # route53_zone_id and wait_for_validation are ignored for EMAIL validation
  wait_for_validation = false

  tags = {
    Project = "integrations"
  }
}
```

> The `aws_acm_certificate_validation` waiter and Route 53 records are **skipped** automatically when `validation_method = "EMAIL"` or `route53_zone_id = null`.

---

### 5. CloudFront certificate (must be in us-east-1)

ACM certificates used with **CloudFront** must be created in the `us-east-1` region, regardless of where your other infrastructure lives. Use a provider alias:

```hcl
# providers.tf
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# main.tf
module "acm_cloudfront" {
  source  = "../tf-aws-acm"

  providers = {
    aws = aws.us_east_1    # <-- required for CloudFront
  }

  name        = "cloudfront-cert"
  environment = "prod"
  domain_name = "cdn.example.com"

  subject_alternative_names = ["*.cdn.example.com"]

  route53_zone_id     = "Z1D633PJN98FT9"
  validation_method   = "DNS"
  wait_for_validation = true

  tags = {
    Project = "cdn"
  }
}

resource "aws_cloudfront_distribution" "this" {
  # ...
  viewer_certificate {
    acm_certificate_arn = module.acm_cloudfront.certificate_arn
    ssl_support_method  = "sni-only"
  }
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name identifier for the certificate (used in tags only). | `string` | — | yes |
| `domain_name` | Primary domain name for the certificate (e.g. `example.com` or `*.example.com`). | `string` | — | yes |
| `environment` | Deployment environment (`dev`, `staging`, `prod`). | `string` | `"dev"` | no |
| `tags` | Additional tags applied to all resources. | `map(string)` | `{}` | no |
| `subject_alternative_names` | Additional domain names (SANs) to include in the certificate. | `list(string)` | `[]` | no |
| `validation_method` | Certificate validation method: `DNS` or `EMAIL`. DNS is recommended — fully automated via Route 53. | `string` | `"DNS"` | no |
| `route53_zone_id` | Route 53 Hosted Zone ID for DNS validation record creation. Required when `validation_method = DNS`. | `string` | `null` | no |
| `wait_for_validation` | Block until the certificate is fully validated and issued. Set `false` for async workflows. | `bool` | `true` | no |
| `key_algorithm` | Certificate key algorithm: `RSA_2048`, `RSA_4096`, `EC_prime256v1`, `EC_secp384r1`. | `string` | `"RSA_2048"` | no |
| `transparency_logging` | Enable certificate transparency logging. Required by modern browsers. | `bool` | `true` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arn` | ARN of the issued ACM certificate. **Paste this into `tf-aws-alb` as `listener_certificate_arn`.** |
| `certificate_domain` | Primary domain name of the certificate. |
| `certificate_status` | Current status of the certificate: `PENDING_VALIDATION`, `ISSUED`, `FAILED`, etc. |
| `certificate_id` | ID of the ACM certificate resource. |
| `domain_validation_options` | Domain validation options — CNAME name/value pairs needed for DNS validation. |
| `validation_record_fqdns` | FQDNs of the Route 53 DNS validation records created by this module. |

---

## Integration with tf-aws-alb

After this module runs, pass `certificate_arn` directly to the ALB module:

```hcl
module "alb" {
  source  = "../tf-aws-alb"

  # ... other inputs ...

  listener_certificate_arn = module.acm.certificate_arn
}
```

The certificate must be in status `ISSUED` before the ALB listener will accept it. Setting `wait_for_validation = true` (the default) ensures this ordering is handled automatically within a single `terraform apply`.

---

## Important Notes

| Topic | Detail |
|-------|--------|
| **CloudFront region** | ACM certificates attached to CloudFront **must** reside in `us-east-1`. Use a provider alias (see example 5). ALB certificates must be in the same region as the ALB. |
| **Wildcard + apex** | `*.example.com` does not cover `example.com`. Always add the bare domain as a SAN when you need both. |
| **DNS propagation** | Validation typically completes in 2–5 minutes after the CNAME records are written. The 30-minute timeout on the waiter handles slow DNS propagation. |
| **SANs deduplication** | ACM deduplicates CNAME records across shared SANs. The `for_each` map uses `domain_name` as the key to prevent duplicate record errors. |
| **Email validation** | Route 53 records and the validation waiter are skipped automatically for `EMAIL` validation. You must click the link in the AWS email before the certificate reaches `ISSUED`. |
| **Transparency logging** | Disabling certificate transparency logging (`transparency_logging = false`) is not recommended and may cause certificate rejection by modern browsers and operating systems. |
| **create_before_destroy** | The `lifecycle` block ensures zero-downtime certificate rotation — a new certificate is fully issued before the old one is destroyed. |
| **Terraform version** | Requires Terraform `>= 1.3.0` for the `for` expression inside `for_each` over `domain_validation_options`. |

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0 |

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_acm_certificate` | The SSL/TLS certificate request. |
| `aws_route53_record` (per domain) | CNAME validation record written to the hosted zone. Only created when `validation_method = DNS` and `route53_zone_id` is set. |
| `aws_acm_certificate_validation` | Waiter that blocks `terraform apply` until the certificate is `ISSUED`. Controlled by `wait_for_validation`. |

