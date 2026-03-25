# dev / staging / qa — uses shared lower-env VPC subnets
aws_region  = "us-east-1"
name        = "app-nva"
environment = "dev"
project     = "platform"
owner       = "network-team"
cost_center = "CC-100"

network_interfaces = {
  # eth1: additional NIC for NVA/firewall (source_dest_check off)
  eth1 = {
    subnet_id          = "subnet-0dev-private"
    security_group_ids = ["sg-0nva"]
    private_ips        = ["10.0.1.100"]
    source_dest_check  = false
    description        = "NVA data-plane interface"
    attachment = {
      instance_id  = "i-0devnvainstance"
      device_index = 1
    }
  }
}
