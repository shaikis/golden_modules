# prod — dedicated VPC, multiple ENIs with EIPs
aws_region  = "us-east-1"
name        = "app-nva"
environment = "prod"
project     = "platform"
owner       = "network-team"
cost_center = "CC-100"

network_interfaces = {
  eth1_mgmt = {
    subnet_id          = "subnet-0prod-mgmt"
    security_group_ids = ["sg-0nva-mgmt"]
    private_ips        = ["10.10.1.100"]
    source_dest_check  = false
    description        = "NVA management interface"
    attachment = {
      instance_id  = "i-0prodnva"
      device_index = 1
    }
    eip = {
      domain                    = "vpc"
      associate_with_private_ip = "10.10.1.100"
    }
  }
  eth2_data = {
    subnet_id          = "subnet-0prod-data"
    security_group_ids = ["sg-0nva-data"]
    private_ips        = ["10.10.2.100"]
    source_dest_check  = false
    description        = "NVA data-plane interface"
    attachment = {
      instance_id  = "i-0prodnva"
      device_index = 2
    }
  }
}
