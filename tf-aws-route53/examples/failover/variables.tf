variable "zone_name" {
  description = "The DNS domain name for the public hosted zone (e.g. 'example.com')."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for resource naming."
  type        = string
  default     = "prod"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "prod"
}

# ── Primary (us-east-1) ALB ──────────────────────────────────────────────────

variable "primary_alb_dns" {
  description = "DNS name of the primary ALB in us-east-1."
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Hosted zone ID of the primary ALB in us-east-1."
  type        = string
}

variable "primary_alb_fqdn" {
  description = "FQDN of the primary API endpoint for the health check."
  type        = string
}

# ── Secondary (eu-west-1) ALB ────────────────────────────────────────────────

variable "secondary_alb_dns" {
  description = "DNS name of the secondary ALB in eu-west-1."
  type        = string
}

variable "secondary_alb_zone_id" {
  description = "Hosted zone ID of the secondary ALB in eu-west-1."
  type        = string
}

variable "secondary_alb_fqdn" {
  description = "FQDN of the secondary API endpoint for the health check."
  type        = string
}

# ── Canary / weighted routing ────────────────────────────────────────────────

variable "prod_alb_dns" {
  description = "DNS name of the production ALB (weighted routing — receives 90% traffic)."
  type        = string
}

variable "prod_alb_zone_id" {
  description = "Hosted zone ID of the production ALB."
  type        = string
}

variable "canary_alb_dns" {
  description = "DNS name of the canary ALB (weighted routing — receives 10% traffic)."
  type        = string
}

variable "canary_alb_zone_id" {
  description = "Hosted zone ID of the canary ALB."
  type        = string
}

# ── Latency routing ──────────────────────────────────────────────────────────

variable "app_us_east_alb_dns" {
  description = "DNS name of the app ALB in us-east-1 (latency routing)."
  type        = string
}

variable "app_us_east_alb_zone_id" {
  description = "Hosted zone ID of the app ALB in us-east-1."
  type        = string
}

variable "app_eu_west_alb_dns" {
  description = "DNS name of the app ALB in eu-west-1 (latency routing)."
  type        = string
}

variable "app_eu_west_alb_zone_id" {
  description = "Hosted zone ID of the app ALB in eu-west-1."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
