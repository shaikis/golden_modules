# Minimal example: one provisioned MSK cluster with sensible defaults.
# Only client_subnets and security_group_ids are required.

module "msk" {
  source = "../../"

  clusters = {
    events = {
      client_subnets     = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
      security_group_ids = ["sg-xxx"]
    }
  }
}
