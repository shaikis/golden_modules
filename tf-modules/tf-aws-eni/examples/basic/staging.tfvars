# staging — dedicated subnets
aws_region  = "us-east-1"
name        = "app-nva"
environment = "staging"
project     = "platform"
owner       = "network-team"
cost_center = "CC-100"

network_interfaces = {
  eth1 = {
    subnet_id          = "subnet-0stg-private"
    security_group_ids = ["sg-0nvastg"]
    private_ips        = ["10.1.1.100"]
    source_dest_check  = false
    description        = "NVA data-plane interface (staging)"
    attachment = {
      instance_id  = "i-0stgnvainstance"
      device_index = 1
    }
  }
}
