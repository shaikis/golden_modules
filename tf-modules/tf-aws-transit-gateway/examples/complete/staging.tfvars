aws_region                      = "us-east-1"
name                            = "enterprise-hub"
name_prefix                     = "staging"
environment                     = "staging"
project                         = "network-core"
owner                           = "network-team"
cost_center                     = "CC-100"
amazon_side_asn                 = 65000
vpn_ecmp_support                = "enable"
default_route_table_association = "disable"
default_route_table_propagation = "disable"
vpc_attachments = {
  shared_services = {
    vpc_id          = "vpc-shared"
    subnet_ids      = ["subnet-ss-a", "subnet-ss-b", "subnet-ss-c"]
    route_table_key = "shared"
  }
  staging_app = {
    vpc_id          = "vpc-app"
    subnet_ids      = ["subnet-app-a", "subnet-app-b", "subnet-app-c"]
    route_table_key = "workloads"
  }
  staging_data = {
    vpc_id          = "vpc-data"
    subnet_ids      = ["subnet-data-a", "subnet-data-b", "subnet-data-c"]
    route_table_key = "workloads"
  }
}
tgw_route_tables = {
  shared    = {}
  workloads = {}
  onprem    = {}
}
tgw_routes = {
  default_to_shared = {
    route_table_key  = "workloads"
    destination_cidr = "0.0.0.0/0"
    attachment_key   = "shared_services"
  }
  onprem_to_all = {
    route_table_key  = "onprem"
    destination_cidr = "10.0.0.0/8"
    attachment_key   = "shared_services"
  }
}
ram_share_enabled             = false
ram_allow_external_principals = false
ram_principals                = []
tags = {
  Environment = "staging"
}
