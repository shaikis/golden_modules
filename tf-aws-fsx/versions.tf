terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    # NetApp ONTAP provider — only required when enable_ontap_snapmirror = true
    # Communicates with FSx ONTAP REST API over HTTPS from within the VPC
    # (run Terraform from a host with network access to the ONTAP management endpoint)
    netapp-ontap = {
      source  = "NetApp/netapp-ontap"
      version = ">= 1.1"
    }
  }
}
