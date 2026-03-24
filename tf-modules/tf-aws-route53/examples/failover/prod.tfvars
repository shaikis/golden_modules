zone_name   = "example.com"
name_prefix = "prod"
environment = "prod"

# Primary ALB — us-east-1
primary_alb_dns     = "prod-api-primary-1234567890.us-east-1.elb.amazonaws.com"
primary_alb_zone_id = "Z35SXDOTRQ7X7K"
primary_alb_fqdn    = "api.example.com"

# Secondary ALB — eu-west-1
secondary_alb_dns     = "prod-api-secondary-0987654321.eu-west-1.elb.amazonaws.com"
secondary_alb_zone_id = "Z32O12XQLNTSW2"
secondary_alb_fqdn    = "api-eu.example.com"

# Weighted routing — production vs canary
prod_alb_dns       = "prod-app-0000000001.us-east-1.elb.amazonaws.com"
prod_alb_zone_id   = "Z35SXDOTRQ7X7K"
canary_alb_dns     = "canary-app-0000000002.us-east-1.elb.amazonaws.com"
canary_alb_zone_id = "Z35SXDOTRQ7X7K"

# Latency routing — multi-region app
app_us_east_alb_dns     = "app-us-east-1111111111.us-east-1.elb.amazonaws.com"
app_us_east_alb_zone_id = "Z35SXDOTRQ7X7K"
app_eu_west_alb_dns     = "app-eu-west-2222222222.eu-west-1.elb.amazonaws.com"
app_eu_west_alb_zone_id = "Z32O12XQLNTSW2"

tags = {
  CostCenter = "engineering"
  Team       = "platform"
}
