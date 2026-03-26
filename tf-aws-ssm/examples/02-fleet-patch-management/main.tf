# =============================================================================
# Example: Enterprise EC2 Fleet Patch Management
# =============================================================================
# Real-world pattern from AWS blog:
# "Patching your Windows EC2 instances using AWS Systems Manager Patch Manager"
# https://aws.amazon.com/blogs/mt/patching-your-windows-ec2-instances-using-aws-systems-manager-patch-manager/
#
# Fleet: 200 mixed EC2 instances
#   - 80x  Windows Server 2022 (IIS web servers, .NET app servers)
#   - 120x Amazon Linux 2023   (API servers, Kafka consumers, ML workers)
#
# Patch strategy:
#   Environment  | Baseline            | Auto-Approve | Window
#   ------------ | ------------------- | ------------ | ------
#   dev          | AL2023 + Win (dev)  | 3 days       | Wed 10:00 UTC
#   test         | AL2023 + Win (test) | 5 days       | Sat 04:00 UTC
#   prod         | AL2023 + Win (prod) | 7 days       | Sun 02:00 UTC
#
# EC2 tagging required:
#   Key: "Patch Group"    Value: "prod-linux" | "prod-windows" | "dev-linux" etc.
#   Key: "Environment"    Value: "prod" | "dev" | "test"
# =============================================================================

module "ssm_patching" {
  source      = "../../"
  name        = "enterprise-fleet"
  environment = "prod"

  # ---------------------------------------------------------------------------
  # PATCH BASELINES
  # One baseline per OS per environment = 6 baselines total
  # ---------------------------------------------------------------------------
  create_patch_baselines = true

  patch_baselines = {

    # -- Amazon Linux 2023 — PRODUCTION ----------------------------------------
    # Critical/Important: auto-approve after 7 days (AWS blog recommendation)
    # Bugfix: auto-approve after 14 days (extra caution in prod)
    "al2023-prod" = {
      operating_system = "AMAZON_LINUX_2023"
      description      = "AL2023 PROD — Critical+Security (7d), Bugfix (14d). Rejected: kernel hotfixes."
      default_baseline = true # This becomes the default for AMAZON_LINUX_2023

      approval_rules = [
        {
          approve_after_days  = 7
          compliance_level    = "CRITICAL"
          enable_non_security = false
          patch_filters = [
            { key = "CLASSIFICATION", values = ["SecurityUpdates"] },
            { key = "SEVERITY", values = ["Critical", "Important"] }
          ]
        },
        {
          approve_after_days  = 14
          compliance_level    = "HIGH"
          enable_non_security = false
          patch_filters = [
            { key = "CLASSIFICATION", values = ["Bugfix"] },
            { key = "SEVERITY", values = ["Critical", "Important", "Medium"] }
          ]
        }
      ]

      rejected_patches = [
        "kernel-ml",        # Exclude mainline kernel — tested separately
        "kernel-ml-headers" # Exclude mainline kernel headers
      ]
    }

    # -- Amazon Linux 2023 — DEVELOPMENT ---------------------------------------
    # Faster approval (3 days) — dev can absorb patches quicker
    # Broader classification to test more patches before they hit prod
    "al2023-dev" = {
      operating_system = "AMAZON_LINUX_2023"
      description      = "AL2023 DEV — all security updates auto-approve after 3 days"
      default_baseline = false

      approval_rules = [
        {
          approve_after_days  = 3
          compliance_level    = "HIGH"
          enable_non_security = true # Include non-security updates in dev
          patch_filters = [
            { key = "CLASSIFICATION", values = ["SecurityUpdates", "Bugfix", "Enhancement"] },
            { key = "SEVERITY", values = ["Critical", "Important", "Medium", "Low"] }
          ]
        }
      ]
    }

    # -- Amazon Linux 2023 — TEST -----------------------------------------------
    "al2023-test" = {
      operating_system = "AMAZON_LINUX_2023"
      description      = "AL2023 TEST — security patches auto-approve after 5 days"
      default_baseline = false

      approval_rules = [
        {
          approve_after_days  = 5
          compliance_level    = "HIGH"
          enable_non_security = false
          patch_filters = [
            { key = "CLASSIFICATION", values = ["SecurityUpdates", "Bugfix"] },
            { key = "SEVERITY", values = ["Critical", "Important"] }
          ]
        }
      ]
    }

    # -- Windows Server 2022 — PRODUCTION ---------------------------------------
    # Microsoft patches: CriticalUpdates (7d), SecurityUpdates (7d)
    # ServicePacks excluded — require manual testing and approval
    "windows-prod" = {
      operating_system = "WINDOWS"
      description      = "Windows 2022 PROD — Critical+Security (7d). Manual approval for ServicePacks."
      default_baseline = true # Default for WINDOWS OS

      approval_rules = [
        {
          approve_after_days = 7
          compliance_level   = "CRITICAL"
          patch_filters = [
            { key = "CLASSIFICATION", values = ["CriticalUpdates", "SecurityUpdates"] },
            { key = "MSRC_SEVERITY", values = ["Critical", "Important"] },
            { key = "PRODUCT", values = ["WindowsServer2022"] }
          ]
        },
        {
          approve_after_days = 21
          compliance_level   = "HIGH"
          patch_filters = [
            { key = "CLASSIFICATION", values = ["UpdateRollups"] },
            { key = "MSRC_SEVERITY", values = ["Critical", "Important"] }
          ]
        }
      ]

      rejected_patches = [
        "KB2999226", # Example: KB that caused issues in environment
        "KB4580325"  # Example: Cumulative update requiring extra testing
      ]

      global_filters = [
        # Only patch Windows Server 2022/2019, not 2016 on same account
        { key = "PRODUCT", values = ["WindowsServer2022", "WindowsServer2019"] }
      ]
    }

    # -- Windows Server — DEVELOPMENT -------------------------------------------
    "windows-dev" = {
      operating_system = "WINDOWS"
      description      = "Windows DEV — broad patching, 3-day auto-approval for all updates"
      default_baseline = false

      approval_rules = [
        {
          approve_after_days = 3
          compliance_level   = "HIGH"
          patch_filters = [
            { key = "CLASSIFICATION", values = ["CriticalUpdates", "SecurityUpdates", "UpdateRollups", "Updates"] },
            { key = "MSRC_SEVERITY", values = ["Critical", "Important", "Moderate"] }
          ]
        }
      ]
    }

    # -- Windows Server — TEST --------------------------------------------------
    "windows-test" = {
      operating_system = "WINDOWS"
      description      = "Windows TEST — 5-day auto-approval for critical+security"
      default_baseline = false

      approval_rules = [
        {
          approve_after_days = 5
          compliance_level   = "CRITICAL"
          patch_filters = [
            { key = "CLASSIFICATION", values = ["CriticalUpdates", "SecurityUpdates"] },
            { key = "MSRC_SEVERITY", values = ["Critical", "Important"] }
          ]
        }
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # PATCH GROUPS
  # Tag EC2 instances with: Key="Patch Group" Value="<patch_group_name>"
  # ---------------------------------------------------------------------------
  patch_groups = {
    # Production Linux (tag: "Patch Group" = "prod-linux")
    "prod-linux"    = "al2023-prod"
    "prod-linux-ml" = "al2023-prod" # ML workers — same baseline, separate group

    # Non-production Linux
    "dev-linux"  = "al2023-dev"
    "test-linux" = "al2023-test"

    # Production Windows (tag: "Patch Group" = "prod-windows")
    "prod-windows"        = "windows-prod"
    "prod-windows-iis"    = "windows-prod" # IIS web servers — separate maintenance window
    "prod-windows-dotnet" = "windows-prod" # .NET app servers

    # Non-production Windows
    "dev-windows"  = "windows-dev"
    "test-windows" = "windows-test"
  }

  # ---------------------------------------------------------------------------
  # MAINTENANCE WINDOWS
  # Production: Sunday 02:00–06:00 UTC (low traffic globally)
  # Test:       Saturday 04:00–07:00 UTC
  # Dev:        Wednesday 10:00–11:00 UTC (business hours, fast feedback)
  # ---------------------------------------------------------------------------
  maintenance_windows = {

    # -- Production Linux Patching ---------------------------------------------
    # Pattern from AWS blog: cron(0 2 ? * SUN *)
    "prod-linux-weekly" = {
      schedule          = "cron(0 2 ? * SUN *)" # Every Sunday 02:00 UTC
      duration          = 4                      # 4-hour window
      cutoff            = 1                      # Stop new tasks 1hr before end
      description       = "Weekly production Linux patching — Sunday 02:00-06:00 UTC"
      enabled           = true
      schedule_timezone = "UTC"
      allow_unassociated_targets = false

      targets = [
        { key = "tag:Patch Group", values = ["prod-linux", "prod-linux-ml"] }
      ]

      tasks = {
        "scan-before-patch" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1        # Run first
          max_concurrency = "10%"    # Patch 10% of fleet at a time
          max_errors      = "5%"     # Stop if >5% of instances fail
          parameters = {
            Operation    = ["Scan"]  # Scan first, see what's missing
            RebootOption = ["NoReboot"]
          }
        }
        "install-patches" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 2        # Run after scan
          max_concurrency = "20%"
          max_errors      = "10%"
          parameters = {
            Operation    = ["Install"]
            RebootOption = ["RebootIfNeeded"] # Auto-reboot if kernel was updated
          }
        }
      }
    }

    # -- Production Windows Patching ------------------------------------------
    "prod-windows-weekly" = {
      schedule          = "cron(0 2 ? * SUN *)" # Same window as Linux (sequential)
      duration          = 4
      cutoff            = 1
      description       = "Weekly production Windows patching — Sunday 02:00-06:00 UTC"
      schedule_timezone = "UTC"

      targets = [
        { key = "tag:Patch Group", values = ["prod-windows", "prod-windows-iis", "prod-windows-dotnet"] }
      ]

      tasks = {
        "install-windows-patches" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "25%"
          max_errors      = "5%"
          parameters = {
            Operation    = ["Install"]
            RebootOption = ["RebootIfNeeded"]
          }
        }
      }
    }

    # -- Test Environment Patching ---------------------------------------------
    "test-all-saturday" = {
      schedule          = "cron(0 4 ? * SAT *)" # Every Saturday 04:00 UTC
      duration          = 3
      cutoff            = 1
      description       = "Test environment patching — Saturday 04:00-07:00 UTC"
      schedule_timezone = "UTC"

      targets = [
        { key = "tag:Environment", values = ["test"] }
      ]

      tasks = {
        "patch-test-fleet" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "50%"  # Can patch faster in test
          max_errors      = "20%"  # Higher error tolerance in test
          parameters = {
            Operation    = ["Install"]
            RebootOption = ["RebootIfNeeded"]
          }
        }
      }
    }

    # -- Development Environment (fast feedback) -------------------------------
    "dev-wednesday-daytime" = {
      schedule          = "cron(0 10 ? * WED *)" # Wednesday 10:00 UTC
      duration          = 1
      cutoff            = 0
      description       = "Dev patching — Wednesday 10:00 UTC (fast feedback cycle)"
      schedule_timezone = "UTC"

      targets = [
        { key = "tag:Environment", values = ["dev"] }
      ]

      tasks = {
        "patch-dev-fleet" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "100%"  # All dev instances at once
          max_errors      = "50%"   # Dev — we want to see failures
          parameters = {
            Operation    = ["Install"]
            RebootOption = ["RebootIfNeeded"]
          }
        }
      }
    }

    # -- Daily Compliance Scan (no install — just report) ---------------------
    "daily-compliance-scan" = {
      schedule          = "cron(0 6 * * ? *)" # Every day at 06:00 UTC
      duration          = 2
      cutoff            = 1
      description       = "Daily patch compliance scan — generates compliance report only"
      schedule_timezone = "UTC"

      targets = [
        { key = "tag:Environment", values = ["prod"] }
      ]

      tasks = {
        "compliance-scan" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "50%"
          max_errors      = "20%"
          parameters = {
            Operation    = ["Scan"]     # Scan only — does NOT install
            RebootOption = ["NoReboot"]
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # STATE MANAGER — Install CloudWatch Agent on all fleet instances
  # ---------------------------------------------------------------------------
  associations = {
    "install-cw-agent-linux" = {
      document_name       = "AWS-ConfigureAWSPackage"
      schedule            = "rate(30 days)"
      compliance_severity = "MEDIUM"
      targets             = [{ key = "tag:Environment", values = ["prod", "test", "dev"] }]
      parameters = {
        action = ["Install"]
        name   = ["AmazonCloudWatchAgent"]
      }
    }

    "gather-patch-inventory" = {
      document_name       = "AWS-GatherSoftwareInventory"
      schedule            = "rate(1 day)"
      compliance_severity = "LOW"
      targets             = [{ key = "InstanceIds", values = ["*"] }]
      parameters          = {}
    }
  }

  tags = {
    CostCenter = "infrastructure"
    Team       = "platform-engineering"
    Compliance = "SOC2"
  }
}

output "patch_baseline_ids" {
  value = module.ssm_patching.patch_baseline_ids
}

output "maintenance_window_ids" {
  value = module.ssm_patching.maintenance_window_ids
}
