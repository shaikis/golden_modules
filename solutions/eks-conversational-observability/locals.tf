locals {
  prefix = "${var.name}-${var.environment}"

  tags = merge(var.tags, {
    Name        = local.prefix
    Environment = var.environment
    Solution    = "eks-conversational-observability"
    ManagedBy   = "terraform"
  })

  kms_key_arn = var.enable_kms ? module.kms[0].key_arns["observability"] : null

  # Derived subnet CIDRs from the VPC CIDR (assumes /16 base)
  # Public:   10.x.0.0/24, 10.x.1.0/24, 10.x.2.0/24
  # Private:  10.x.10.0/24, 10.x.11.0/24, 10.x.12.0/24
  vpc_octet = split(".", var.vpc_cidr)[1]

  public_subnet_cidrs = [
    "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}.0.0/24",
    "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}.1.0/24",
    "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}.2.0/24",
  ]

  private_subnet_cidrs = [
    "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}.10.0/24",
    "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}.11.0/24",
    "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}.12.0/24",
  ]
}
