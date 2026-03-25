environment = "dev"

prefix_lists = {
  internal = {
    name = "dev-internal-pl"

    entries_list = [
      "10.0.0.0/24",
      "10.0.1.0/24",
      "10.0.0.0/24" # duplicate → auto removed
    ]
  }

  external = {
    name = "dev-external-pl"

    entries_list = [
      "0.0.0.0/0"
    ]
  }

  partners = {
    name = "dev-partner-pl"

    entries_list = [
      "172.16.0.0/16",
      "172.16.1.0/24"
    ]
  }
}