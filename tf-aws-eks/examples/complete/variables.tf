variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "platform-eks"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = "platform"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "cost_center" {
  type    = string
  default = "CC-400"
}

variable "tags" {
  type = map(string)
  default = {
    Tier = "platform"
  }
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "vpc_id" {
  type    = string
  default = "vpc-1234567890abcdef0"
}

variable "control_plane_subnet_ids" {
  type    = list(string)
  default = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
}

variable "node_group_subnet_ids" {
  type    = list(string)
  default = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "node_groups" {
  type = map(object({
    ami_type        = optional(string, "AL2_x86_64")
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "ON_DEMAND")
    disk_size       = optional(number, 50)
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 5)
    max_unavailable = optional(number, 1)
    subnet_ids      = optional(list(string), [])
    labels          = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, null)
      effect = string
    })), [])
    kms_key_arn             = optional(string, null)
    launch_template_id      = optional(string, null)
    launch_template_version = optional(string, null)
  }))
  default = {
    system = {
      instance_types = ["t3.large"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      labels = {
        workload = "system"
      }
    }
    apps = {
      instance_types = ["m5.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      labels = {
        workload = "apps"
      }
      taints = [{
        key    = "workload"
        value  = "apps"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}

variable "fargate_profiles" {
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    subnet_ids = optional(list(string), [])
  }))
  default = {
    platform = {
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "metrics-server"
          }
        },
        {
          namespace = "observability"
        }
      ]
    }
  }
}

variable "cluster_addons" {
  type = map(object({
    addon_version               = optional(string, null)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    service_account_role_arn    = optional(string, null)
    configuration_values        = optional(string, null)
  }))
  default = {
    coredns            = {}
    kube-proxy         = {}
    vpc-cni            = {}
    aws-ebs-csi-driver = {}
  }
}
