# =============================================================================
# Example: Failover, Weighted, and Latency Routing Policies
#
# Demonstrates three advanced routing strategies:
#
# 1. FAILOVER ROUTING (api.example.com)
#    Active-passive high availability across two regions.
#    - PRIMARY:   us-east-1 ALB — receives all traffic when healthy
#    - SECONDARY: eu-west-1 ALB — receives traffic only if PRIMARY is unhealthy
#    - Health checks on both endpoints (HTTPS /health)
#    - Calculated health check: global check = 1 of 2 regional checks passing
#
# 2. WEIGHTED ROUTING (app.example.com — canary deploy)
#    Traffic split by percentage using weights (0–255).
#    - prod ALB   → weight 90 — receives ~90% of traffic
#    - canary ALB → weight 10 — receives ~10% of traffic (new version)
#    Use case: gradually roll out new application versions and monitor errors
#    before shifting 100% of traffic.
#
# 3. LATENCY-BASED ROUTING (app.example.com)
#    Route clients to the AWS region with the lowest measured latency.
#    - us-east-1: serves North American users
#    - eu-west-1: serves European users
#    AWS measures latency from the client to each region and routes accordingly.
#    Latency routing is NOT failover — use health checks to avoid routing to
#    unhealthy endpoints.
# =============================================================================

module "route53" {
  source = "../../"

  name        = "failover"
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags

  # ── Hosted Zone ─────────────────────────────────────────────────────────────
  zones = {
    main = {
      name    = var.zone_name
      comment = "Production zone with failover, weighted, and latency routing"
    }
  }

  # ── Health Checks ─────────────────────────────────────────────────────────
  # Endpoint health checks: Route 53 polls the endpoint every 30 seconds
  # from multiple locations around the world.
  health_checks = {
    # Primary endpoint in us-east-1 — HTTPS check on /health path
    api_us_east = {
      type              = "HTTPS"
      fqdn              = var.primary_alb_fqdn
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
      name              = "api-primary-us-east-1"
    }

    # Secondary endpoint in eu-west-1 — same HTTPS check
    api_eu_west = {
      type              = "HTTPS"
      fqdn              = var.secondary_alb_fqdn
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
      name              = "api-secondary-eu-west-1"
    }
  }

  # ── Calculated Health Check ────────────────────────────────────────────────
  # Combines regional checks: healthy if AT LEAST 1 of 2 regions is passing.
  # This prevents a false outage if only one region's health check fails.
  calculated_health_checks = {
    api_global = {
      child_health_check_keys = ["api_us_east", "api_eu_west"]
      child_health_threshold  = 1 # N-of-M: 1 out of 2 must be healthy
      name                    = "api-global-calculated"
    }
  }

  # ── DNS Records ───────────────────────────────────────────────────────────
  records = {
    # ── Failover: PRIMARY ────────────────────────────────────────────────────
    # api.example.com → us-east-1 ALB (alias, no TTL)
    # When this endpoint's health check passes, it receives ALL traffic.
    api_primary = {
      zone_key         = "main"
      name             = "api.${var.zone_name}"
      type             = "A"
      set_identifier   = "primary-us-east-1"
      failover_role    = "PRIMARY"
      health_check_key = "api_us_east"
      alias_target = {
        name                   = var.primary_alb_dns
        zone_id                = var.primary_alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Failover: SECONDARY ───────────────────────────────────────────────────
    # api.example.com → eu-west-1 ALB (failover target)
    # Only receives traffic when PRIMARY health check fails.
    api_secondary = {
      zone_key         = "main"
      name             = "api.${var.zone_name}"
      type             = "A"
      set_identifier   = "secondary-eu-west-1"
      failover_role    = "SECONDARY"
      health_check_key = "api_eu_west"
      alias_target = {
        name                   = var.secondary_alb_dns
        zone_id                = var.secondary_alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Weighted: Production (90%) ────────────────────────────────────────────
    # app.example.com → prod ALB → ~90% of traffic
    # Weight values are proportional: 90/(90+10) = 90%
    app_prod = {
      zone_key       = "main"
      name           = "app.${var.zone_name}"
      type           = "A"
      set_identifier = "prod-v1"
      weight         = 90
      alias_target = {
        name                   = var.prod_alb_dns
        zone_id                = var.prod_alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Weighted: Canary (10%) ────────────────────────────────────────────────
    # app.example.com → canary ALB → ~10% of traffic
    # Canary receives a small slice for testing before full rollout.
    app_canary = {
      zone_key       = "main"
      name           = "app.${var.zone_name}"
      type           = "A"
      set_identifier = "canary-v2"
      weight         = 10
      alias_target = {
        name                   = var.canary_alb_dns
        zone_id                = var.canary_alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Latency: us-east-1 ────────────────────────────────────────────────────
    # Clients with lowest latency to us-east-1 are routed here automatically.
    # Route 53 uses periodic latency measurements (not per-request).
    latency_us_east = {
      zone_key       = "main"
      name           = "service.${var.zone_name}"
      type           = "A"
      set_identifier = "us-east-1"
      latency_region = "us-east-1"
      alias_target = {
        name                   = var.app_us_east_alb_dns
        zone_id                = var.app_us_east_alb_zone_id
        evaluate_target_health = true
      }
    }

    # ── Latency: eu-west-1 ────────────────────────────────────────────────────
    # Clients with lowest latency to eu-west-1 are routed here automatically.
    latency_eu_west = {
      zone_key       = "main"
      name           = "service.${var.zone_name}"
      type           = "A"
      set_identifier = "eu-west-1"
      latency_region = "eu-west-1"
      alias_target = {
        name                   = var.app_eu_west_alb_dns
        zone_id                = var.app_eu_west_alb_zone_id
        evaluate_target_health = true
      }
    }
  }
}
