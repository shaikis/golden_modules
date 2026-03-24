# =============================================================================
# Example: Complete — All Module Features
#
# Demonstrates every feature of the tf-aws-route53 module:
#
#   ✓ Public hosted zone (created by module)
#   ✓ Private hosted zone with VPC association
#   ✓ Reusable delegation set
#   ✓ All record types: A, AAAA, CNAME, MX, TXT, NS, CAA, PTR
#   ✓ All routing policies: simple, weighted, latency, failover,
#                           geolocation, multivalue, IP-based
#   ✓ Alias records (ALB)
#   ✓ HTTPS endpoint health checks
#   ✓ Calculated health check (N-of-M)
#   ✓ CloudWatch alarm health check (for private RDS)
#   ✓ DNSSEC (optional — requires KMS key)
#   ✓ Route 53 Resolver inbound + outbound endpoints
#   ✓ Resolver forwarding rules for on-premises domains
#   ✓ DNS Firewall with custom domain list + rule group
#   ✓ DNS Firewall VPC association
#   ✓ CIDR collection for IP-based routing (optional)
# =============================================================================

module "route53" {
  source = "../../"

  name        = "complete"
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags

  # ============================================================================
  # DELEGATION SETS
  # Creates a reusable delegation set so the same NS records can be used
  # across all environments (dev, staging, prod) without re-registering NS
  # at the registrar every time you recreate a zone.
  # ============================================================================
  create_delegation_sets = {
    primary = {
      reference_name = "primary-delegation-set"
    }
  }

  # ============================================================================
  # HOSTED ZONES
  # ============================================================================
  zones = {
    # Public zone — internet-accessible DNS
    public = {
      name    = var.public_zone_name
      comment = "Primary public hosted zone — managed by Terraform"
    }

    # Private zone — only resolvable within the associated VPC
    # Useful for internal service discovery (RDS endpoints, internal ALBs, etc.)
    private = {
      name         = var.private_zone_name
      comment      = "Internal private zone — VPC DNS resolution only"
      private_zone = true
      vpc_ids      = [var.vpc_id]
    }
  }

  # ============================================================================
  # HEALTH CHECKS
  # ============================================================================

  health_checks = {
    # Primary API endpoint — HTTPS health check from multiple AWS regions
    api_primary = {
      type              = "HTTPS"
      fqdn              = "api.${var.public_zone_name}"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
      measure_latency   = true
      name              = "api-primary-https"
    }

    # Secondary API endpoint — used in failover configuration
    api_secondary = {
      type              = "HTTPS"
      fqdn              = "api-secondary.${var.public_zone_name}"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
      name              = "api-secondary-https"
    }
  }

  # Calculated health check: healthy if AT LEAST 1 of 2 endpoint checks pass
  calculated_health_checks = {
    api_global = {
      child_health_check_keys = ["api_primary", "api_secondary"]
      child_health_threshold  = 1
      name                    = "api-global-calculated"
    }
  }

  # CloudWatch alarm-based health check — for private resources Route 53 cannot reach
  # This check uses the state of a CW alarm rather than polling an HTTP endpoint.
  # Useful for: RDS instances, internal load balancers, EC2 in private subnets.
  cloudwatch_alarm_health_checks = {
    rds_primary = {
      alarm_name                      = var.rds_cloudwatch_alarm_name
      alarm_region                    = "us-east-1"
      insufficient_data_health_status = "Unhealthy"
      name                            = "rds-primary-cw-alarm"
    }
  }

  # ============================================================================
  # DNS RECORDS — All types and routing policies
  # ============================================================================

  records = {
    # ── Simple records ─────────────────────────────────────────────────────────

    # Zone apex A record
    apex_a = {
      zone_key = "public"
      name     = var.public_zone_name
      type     = "A"
      ttl      = 300
      records  = ["203.0.113.10"]
    }

    # Zone apex AAAA record (IPv6)
    apex_aaaa = {
      zone_key = "public"
      name     = var.public_zone_name
      type     = "AAAA"
      ttl      = 300
      records  = ["2001:db8::1"]
    }

    # www CNAME → apex
    www_cname = {
      zone_key = "public"
      name     = "www.${var.public_zone_name}"
      type     = "CNAME"
      ttl      = 300
      records  = [var.public_zone_name]
    }

    # MX records for email
    mail_mx = {
      zone_key = "public"
      name     = var.public_zone_name
      type     = "MX"
      ttl      = 3600
      records  = ["10 mail.${var.public_zone_name}.", "20 mail2.${var.public_zone_name}."]
    }

    # SPF TXT — authorized email senders
    spf_txt = {
      zone_key = "public"
      name     = var.public_zone_name
      type     = "TXT"
      ttl      = 3600
      records  = ["\"v=spf1 include:_spf.google.com ~all\""]
    }

    # DMARC TXT — email authentication policy
    dmarc_txt = {
      zone_key = "public"
      name     = "_dmarc.${var.public_zone_name}"
      type     = "TXT"
      ttl      = 3600
      records  = ["\"v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.public_zone_name}; pct=100\""]
    }

    # CAA — restrict certificate authorities
    apex_caa = {
      zone_key = "public"
      name     = var.public_zone_name
      type     = "CAA"
      ttl      = 3600
      records = [
        "0 issue \"letsencrypt.org\"",
        "0 issue \"amazon.com\"",
        "0 issuewild \"letsencrypt.org\"",
        "0 iodef \"mailto:security@${var.public_zone_name}\"",
      ]
    }

    # NS record for subdomain delegation to a separate zone
    staging_ns = {
      zone_key = "public"
      name     = "staging.${var.public_zone_name}"
      type     = "NS"
      ttl      = 172800
      records = [
        "ns-100.awsdns-12.com.",
        "ns-200.awsdns-25.net.",
        "ns-300.awsdns-37.org.",
        "ns-400.awsdns-50.co.uk.",
      ]
    }

    # PTR record (reverse DNS) — in a dedicated reverse-lookup zone
    # Note: PTR records live in a separate zone like 113.0.203.in-addr.arpa
    # Shown here for completeness — zone_id would reference that reverse zone
    # ptr_apex = {
    #   zone_id = "ZEXAMPLEREVERSEZONE"
    #   name    = "10.113.0.203.in-addr.arpa"
    #   type    = "PTR"
    #   ttl     = 300
    #   records = ["${var.public_zone_name}."]
    # }

    # ── Private zone record ───────────────────────────────────────────────────

    # Internal RDS endpoint — only resolvable within the VPC
    rds_internal = {
      zone_key = "private"
      name     = "rds.${var.private_zone_name}"
      type     = "CNAME"
      ttl      = 60
      records  = ["prod-rds.cluster-abcdef123456.us-east-1.rds.amazonaws.com"]
    }

    # Internal service A record
    internal_api = {
      zone_key = "private"
      name     = "api.${var.private_zone_name}"
      type     = "A"
      ttl      = 60
      records  = ["10.0.1.100", "10.0.2.100"]
    }

    # ── Alias record (ALB) ───────────────────────────────────────────────────

    # ALB alias — no TTL for alias records (AWS manages TTL internally)
    alb_alias = {
      zone_key = "public"
      name     = "app.${var.public_zone_name}"
      type     = "A"
      alias_target = {
        name                   = var.alb_dns_name
        zone_id                = var.alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Failover routing ──────────────────────────────────────────────────────

    api_failover_primary = {
      zone_key         = "public"
      name             = "api.${var.public_zone_name}"
      type             = "A"
      set_identifier   = "primary"
      failover_role    = "PRIMARY"
      health_check_key = "api_primary"
      alias_target = {
        name                   = var.alb_dns_name
        zone_id                = var.alb_zone_id
        evaluate_target_health = true
      }
    }

    api_failover_secondary = {
      zone_key         = "public"
      name             = "api.${var.public_zone_name}"
      type             = "A"
      set_identifier   = "secondary"
      failover_role    = "SECONDARY"
      health_check_key = "api_secondary"
      alias_target = {
        name                   = var.secondary_alb_dns_name
        zone_id                = var.secondary_alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Weighted routing ──────────────────────────────────────────────────────

    # 90% production traffic
    weighted_prod = {
      zone_key       = "public"
      name           = "weighted.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.20"]
      set_identifier = "prod"
      weight         = 90
    }

    # 10% canary traffic
    weighted_canary = {
      zone_key       = "public"
      name           = "weighted.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.21"]
      set_identifier = "canary"
      weight         = 10
    }

    # ── Latency-based routing ─────────────────────────────────────────────────

    latency_us_east = {
      zone_key       = "public"
      name           = "latency.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.30"]
      set_identifier = "us-east-1"
      latency_region = "us-east-1"
    }

    latency_eu_west = {
      zone_key       = "public"
      name           = "latency.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.31"]
      set_identifier = "eu-west-1"
      latency_region = "eu-west-1"
    }

    # ── Geolocation routing ───────────────────────────────────────────────────

    # North American users → us-east-1
    geo_na = {
      zone_key       = "public"
      name           = "geo.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.40"]
      set_identifier = "geo-na"
      geolocation = {
        continent = "NA"
      }
    }

    # European users → eu-west-1
    geo_eu = {
      zone_key       = "public"
      name           = "geo.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.41"]
      set_identifier = "geo-eu"
      geolocation = {
        continent = "EU"
      }
    }

    # Default (all other continents) — must have a wildcard geolocation rule
    geo_default = {
      zone_key       = "public"
      name           = "geo.${var.public_zone_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.42"]
      set_identifier = "geo-default"
      geolocation = {
        country = "*"
      }
    }

    # ── Multivalue answer routing ─────────────────────────────────────────────
    # Returns up to 8 healthy IPs; clients pick one at random (client-side LB).
    # Differs from simple round-robin: Route 53 checks health before returning IPs.

    multivalue_a = {
      zone_key          = "public"
      name              = "multi.${var.public_zone_name}"
      type              = "A"
      ttl               = 60
      records           = ["203.0.113.50"]
      set_identifier    = "multi-1"
      multivalue_answer = true
    }

    multivalue_b = {
      zone_key          = "public"
      name              = "multi.${var.public_zone_name}"
      type              = "A"
      ttl               = 60
      records           = ["203.0.113.51"]
      set_identifier    = "multi-2"
      multivalue_answer = true
    }

    multivalue_c = {
      zone_key          = "public"
      name              = "multi.${var.public_zone_name}"
      type              = "A"
      ttl               = 60
      records           = ["203.0.113.52"]
      set_identifier    = "multi-3"
      multivalue_answer = true
    }
  }

  # ============================================================================
  # CIDR COLLECTION (IP-based routing)
  # Conditionally created — only when enable_cidr_routing = true.
  # Route clients from specific IP ranges to designated endpoints.
  # ============================================================================
  cidr_collections = var.enable_cidr_routing ? {
    corporate = {
      locations = {
        us_offices = {
          cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
        }
        eu_offices = {
          cidr_blocks = ["192.168.0.0/16"]
        }
      }
    }
  } : {}

  # ============================================================================
  # DNSSEC
  # Conditionally enabled — only when enable_dnssec = true and a KMS key is set.
  # Adds the zone signing key and enables Route 53 DNSSEC signing.
  # After enabling, add the DS record output to your parent zone / registrar.
  # ============================================================================
  dnssec_zones = var.enable_dnssec && var.dnssec_kms_key_arn != null ? {
    public = {
      kms_key_arn          = var.dnssec_kms_key_arn
      key_signing_key_name = "KSK1"
      signing_status       = "SIGNING"
    }
  } : {}

  # ============================================================================
  # ROUTE 53 RESOLVER
  # Enables hybrid DNS between AWS VPCs and on-premises networks.
  # Only create when resolver_subnet_ids and security groups are provided.
  # ============================================================================
  resolver_endpoints = length(var.resolver_subnet_ids) >= 2 && length(var.resolver_security_group_ids) > 0 ? {
    # Inbound: on-premises DNS servers forward *.internal.example.com queries here
    inbound = {
      direction          = "INBOUND"
      security_group_ids = var.resolver_security_group_ids
      ip_addresses = [
        { subnet_id = var.resolver_subnet_ids[0] },
        { subnet_id = var.resolver_subnet_ids[1] },
      ]
      protocols = ["Do53"]
    }

    # Outbound: AWS forwards *.corp.example.com queries to on-premises DNS
    outbound = {
      direction          = "OUTBOUND"
      security_group_ids = var.resolver_security_group_ids
      ip_addresses = [
        { subnet_id = var.resolver_subnet_ids[0] },
        { subnet_id = var.resolver_subnet_ids[1] },
      ]
      protocols = ["Do53"]
    }
  } : {}

  resolver_rules = length(var.resolver_subnet_ids) >= 2 && length(var.on_premises_dns_ips) > 0 ? {
    # Forward corp.example.com domain queries to on-premises DNS servers
    corp_domain = {
      domain_name           = "corp.example.com"
      rule_type             = "FORWARD"
      resolver_endpoint_key = "outbound"
      target_ips = [
        for ip in var.on_premises_dns_ips : { ip = ip, port = 53 }
      ]
      vpc_ids = [var.vpc_id]
    }
  } : {}

  # ============================================================================
  # DNS FIREWALL
  # Blocks outbound DNS queries from the VPC to known malicious domains.
  # ============================================================================
  dns_firewall_domain_lists = {
    # Custom block list — crypto-mining and known malware C2 domains
    malicious_domains = {
      name = "complete-example-malicious-domains"
      domains = [
        "pool.minexmr.com",
        "xmr.pool.minergate.com",
        "*.nicehash.com",
        "*.cryptonight.net",
      ]
    }
  }

  dns_firewall_rule_groups = {
    security = {
      rules = {
        # Priority 100: block known crypto-mining domains with NXDOMAIN response
        block_crypto_mining = {
          priority        = 100
          action          = "BLOCK"
          domain_list_key = "malicious_domains"
          block_response  = "NXDOMAIN"
        }
      }
    }
  }

  # Associate the security rule group with the VPC
  dns_firewall_associations = {
    security_vpc = {
      rule_group_key      = "security"
      vpc_id              = var.vpc_id
      priority            = 101
      mutation_protection = "DISABLED"
    }
  }
}
