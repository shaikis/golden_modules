# tf-aws-cloudfront — Examples

> Quick-start examples for the `tf-aws-cloudfront` Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [basic-s3-website](basic-s3-website/) | Minimal config — public S3 static website with HTTPS and global edge caching; ideal starting point |
| [spa-s3-oac](spa-s3-oac/) | Private S3 bucket + Origin Access Control (OAC) for a React/Angular/Vue SPA; aggressive asset caching with cache-busting headers |
| [alb-backend](alb-backend/) | CloudFront in front of an internal ALB (ECS/EKS/EC2); secret-header protection, WAF, Origin Shield, static + dynamic cache behaviors |
| [multi-origin-path-routing](multi-origin-path-routing/) | Single distribution with three origins — S3 (static assets, OAC), ALB (API `/api/*`), and a private media bucket (`/media/*`, `/uploads/*`) |
| [lambda-edge-functions](lambda-edge-functions/) | CloudFront Functions for JWT auth + URL normalisation at the viewer layer; Lambda@Edge for A/B testing and canary traffic splitting at the origin layer |
| [origin-failover-group](origin-failover-group/) | CloudFront Origin Group with automatic S3 cross-region failover (us-east-1 → us-west-2) on 5xx errors using OAC on both buckets |
| [realtime-payment-api](realtime-payment-api/) | Full config — CloudFront in front of API Gateway for a PCI-DSS payment platform; CachingDisabled, TLS 1.2+, security headers, WAF, Origin Shield |

## Architecture

```mermaid
graph LR
    subgraph Viewers["Viewers"]
        style Viewers fill:#232F3E,color:#fff,stroke:#232F3E
        USER["Users / Clients"]
        R53["Route 53 Alias"]
        USER --> R53
    end

    subgraph Edge["CloudFront Edge Network"]
        style Edge fill:#FF9900,color:#fff,stroke:#FF9900
        CF["CloudFront Distribution\n(cache behaviors, geo restriction)"]
        WAF["AWS WAF WebACL"]
        CFN["CloudFront Function\n(viewer-request/response)"]
        LAE["Lambda@Edge\n(origin-request/response)"]
        ACM["ACM Certificate\n(us-east-1)"]
        R53 --> CF
        CF --> WAF
        CF --> CFN
        CF --> LAE
        ACM --> CF
    end

    subgraph Origins["Origins"]
        style Origins fill:#1A9C3E,color:#fff,stroke:#1A9C3E
        S3_OAC["S3 Bucket\n(private + OAC)"]
        S3_WEB["S3 Static Website\n(public)"]
        ALB["Application Load Balancer\n(secret header)"]
        APIGW["API Gateway"]
        OG["Origin Group\nprimary + failover S3"]
    end

    subgraph Logging["Observability"]
        style Logging fill:#8C4FFF,color:#fff,stroke:#8C4FFF
        S3LOG["S3 Access Logs"]
        KIN["Kinesis Real-time Logs"]
    end

    CF --> S3_OAC
    CF --> S3_WEB
    CF --> ALB
    CF --> APIGW
    CF --> OG
    CF --> S3LOG
    CF --> KIN
```

## Running an Example

```bash
cd basic-s3-website
terraform init
terraform apply -var-file="dev.tfvars"
```
