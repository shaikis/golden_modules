# ===========================================================================
# NAMING & TAGGING
# ===========================================================================
variable "name" {
  description = "Name for the ARC cluster and resources."
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix prepended to name."
  type        = string
  default     = ""
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ===========================================================================
# ARC CLUSTER
# ARC clusters are global, 5-node infrastructure that host routing control state.
# Each cluster is independent of AWS regions — survives a full regional failure.
# ===========================================================================
variable "create_cluster" {
  description = <<-EOT
    Create a new ARC cluster. Clusters are expensive (~$2.50/hr each) and you typically
    share one cluster across many applications. Set to false and provide cluster_arn to
    reuse an existing cluster.
  EOT
  type    = bool
  default = true
}

variable "cluster_arn" {
  description = "ARN of an existing ARC cluster to reuse (when create_cluster = false)."
  type        = string
  default     = null
}

# ===========================================================================
# CONTROL PANELS
# A control panel is a logical grouping of routing controls within a cluster.
# ===========================================================================
variable "control_panels" {
  description = <<-EOT
    Map of control panel configurations.
    Each control panel groups related routing controls (e.g. one per application or per region-pair).

    Key = logical name (used as reference key in routing_controls and safety_rules):
      name - Control panel display name (defaults to key)
  EOT
  type = map(object({
    name = optional(string, null)
  }))
  default = {
    default = {}
  }
}

# ===========================================================================
# ROUTING CONTROLS
# Binary on/off switches that control whether traffic is routed to a cell/region.
# Toggling a routing control triggers Route 53 health check state changes.
# ===========================================================================
variable "routing_controls" {
  description = <<-EOT
    Map of routing control configurations.
    Each routing control represents a traffic switch for one cell (region/AZ/deployment).

    Key = logical name (used in safety_rules and health_checks):
      name              - Display name (defaults to key)
      control_panel_key - Key from var.control_panels (which panel this belongs to)
  EOT
  type = map(object({
    name              = optional(string, null)
    control_panel_key = optional(string, "default")
  }))
  default = {}
}

# ===========================================================================
# SAFETY RULES
# Prevent unsafe failover operations (e.g. turning off ALL cells simultaneously).
# Two types:
#   ASSERTION: Enforces a minimum number of controls in a specific state
#   GATING:    Requires a gating control to be ON before allowing changes to target controls
# ===========================================================================
variable "safety_rules" {
  description = <<-EOT
    Map of safety rule configurations to prevent dangerous routing control combinations.

    Key = logical name:
      name              - Safety rule name
      control_panel_key - Panel this rule belongs to
      type              - ASSERTION | GATING
      wait_period_ms    - Milliseconds to wait before applying the state change (0-5000)

    For ASSERTION rules:
      asserted_controls   - List of routing control keys to assert on
      assertion_rule:
        inverted         - If true, assert controls are OFF (not ON)
        threshold        - Minimum number of controls that must satisfy the rule
        type             - ATLEAST | AND | OR

    For GATING rules:
      gating_controls      - List of routing control keys that act as the gate
      target_controls      - List of routing control keys that are controlled by the gate
      gating_rule:
        inverted           - If true, gate must be OFF (not ON)
        threshold          - Minimum gating controls that must satisfy rule
        type               - ATLEAST | AND | OR
  EOT
  type = map(object({
    name              = string
    control_panel_key = optional(string, "default")
    type              = string  # ASSERTION | GATING
    wait_period_ms    = optional(number, 5000)

    # ASSERTION rule fields
    asserted_controls = optional(list(string), [])
    assertion_rule = optional(object({
      inverted  = optional(bool, false)
      threshold = number
      type      = optional(string, "ATLEAST")
    }), null)

    # GATING rule fields
    gating_controls = optional(list(string), [])
    target_controls  = optional(list(string), [])
    gating_rule = optional(object({
      inverted  = optional(bool, false)
      threshold = number
      type      = optional(string, "ATLEAST")
    }), null)
  }))
  default = {}
}

# ===========================================================================
# ROUTE 53 HEALTH CHECKS (Routing Control Health Checks)
# These health checks are tied to routing controls.
# Route 53 uses the routing control state to determine DNS health.
# ===========================================================================
variable "health_checks" {
  description = <<-EOT
    Map of Route 53 routing control health checks.
    Each health check reflects the ON/OFF state of a routing control,
    and is used in Route 53 DNS failover records.

    Key = logical name:
      routing_control_key - Key from var.routing_controls
      name                - Health check name tag
      disabled            - Create the health check in disabled state (useful during initial setup)
  EOT
  type = map(object({
    routing_control_key = string
    name                = optional(string, null)
    disabled            = optional(bool, false)
  }))
  default = {}
}

# ===========================================================================
# READINESS CHECKS
# Validate that resources in each cell are ready to serve traffic BEFORE failover.
# ===========================================================================
variable "readiness_checks" {
  description = <<-EOT
    Map of readiness check configurations.
    Readiness checks continuously monitor whether recovery resources are prepared
    to absorb traffic (capacity, configuration, replication lag, etc.).

    Key = logical name:
      resource_set_name  - Name for the resource set
      resource_set_type  - AWS resource type ARN format:
        AWS::Route53RecoveryReadiness::DNSTargetResource
        AWS::AutoScaling::AutoScalingGroup
        AWS::EC2::CustomerGateway
        AWS::EC2::Instance
        AWS::EC2::NetworkInterface
        AWS::EC2::SecurityGroup
        AWS::EC2::Volume
        AWS::ElasticLoadBalancingV2::LoadBalancer
        AWS::Lambda::Function
        AWS::MSK::Cluster
        AWS::DynamoDB::Table
        AWS::RDS::DBCluster
        AWS::RDS::DBInstance
        AWS::SQS::Queue
        AWS::SNS::Topic
        AWS::ECS::Service
        AWS::EKS::Nodegroup
      resources          - List of resource configurations:
        component_id    - Unique identifier (e.g. "primary" or "failover")
        resource_arn    - ARN of the resource to monitor
        dns_target_resource - For DNS-based readiness (optional)
  EOT
  type = map(object({
    resource_set_name = string
    resource_set_type = string
    resources = list(object({
      component_id = string
      resource_arn = string
      dns_target_resource = optional(object({
        domain_name            = string
        hosted_zone_arn        = optional(string, null)
        record_set_id          = optional(string, null)
        record_type            = optional(string, "A")
        target_resource_arn    = optional(string, null)
      }), null)
    }))
  }))
  default = {}
}

# ===========================================================================
# RECOVERY GROUPS
# A recovery group represents the entire application.
# It contains cells (regions/AZs) and readiness checks.
# ===========================================================================
variable "recovery_group" {
  description = <<-EOT
    Recovery group configuration for the application.
      name  - Recovery group name
      cells - List of cell configurations:
        name   - Cell name (e.g. "primary-us-east-1", "failover-us-west-2")
        zones  - List of zone ARNs or empty list
  EOT
  type = object({
    name = string
    cells = list(object({
      name  = string
      zones = optional(list(string), [])
    }))
  })
  default = null
}
