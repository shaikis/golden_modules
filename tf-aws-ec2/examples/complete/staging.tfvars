aws_region  = "us-east-1"
name        = "app-server"
name_prefix = ""
environment = "staging"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

ami_id            = ""
instance_type     = "t3.medium"
subnet_id         = "subnet-0stgprivate1"
vpc_id            = "vpc-0stagingvpc"
key_name          = null
availability_zone = null
tenancy           = "default"
placement_group   = null
get_password_data = false
instance_initiated_shutdown_behavior = "stop"

user_data                   = null
user_data_base64            = null
user_data_replace_on_change = false

associate_public_ip_address = false
private_ip                  = null
secondary_private_ips       = []
source_dest_check           = true

disable_api_termination = false
disable_api_stop        = false
monitoring              = true

root_volume_type                  = "gp3"
root_volume_size                  = 30
root_volume_iops                  = null
root_volume_throughput            = null
root_volume_encrypted             = true
root_volume_delete_on_termination = true

ebs_volumes      = {}
cpu_credits      = null
cpu_options      = null
metadata_options = { http_endpoint = "enabled"; http_tokens = "required"; http_put_response_hop_limit = 1; instance_metadata_tags = "enabled" }

create_eip = false
use_spot   = false
spot_price = null
