module "ses" {
  source = "../../"

  # ── Feature gates ─────────────────────────────────────────────────────────
  create_configuration_sets = true
  create_receipt_rules      = true
  create_templates          = true
  create_iam_roles          = true

  # ── Domain Identities ────────────────────────────────────────────────────────

  domain_identities = {
    primary = {
      domain                           = "example.com"
      dkim_signing                     = true
      mail_from_domain                 = "mail.example.com"
      mail_from_behavior_on_mx_failure = "USE_DEFAULT_VALUE"
      configuration_set_name           = "transactional"
      tags = {
        Purpose = "transactional-sending"
      }
    }
    newsletter = {
      domain                           = "newsletter.example.com"
      dkim_signing                     = true
      mail_from_domain                 = "bounce.newsletter.example.com"
      mail_from_behavior_on_mx_failure = "REJECT_MESSAGE"
      configuration_set_name           = "marketing"
      tags = {
        Purpose = "marketing-sending"
      }
    }
  }

  # ── Email Address Identities ─────────────────────────────────────────────────

  email_identities = {
    noreply = {
      email_address          = "noreply@example.com"
      configuration_set_name = "transactional"
    }
    support = {
      email_address          = "support@example.com"
      configuration_set_name = "transactional"
    }
  }

  # ── Configuration Sets ───────────────────────────────────────────────────────

  configuration_sets = {
    transactional = {
      sending_enabled            = true
      reputation_metrics_enabled = true
      suppression_reasons        = ["BOUNCE", "COMPLAINT"]
      engagement_metrics         = false
      optimized_shared_delivery  = false
      custom_redirect_domain     = null
      tags = {
        Tier = "transactional"
      }

      event_destinations = {
        bounce_sns = {
          enabled = true
          event_types = [
            "BOUNCE",
            "COMPLAINT",
            "REJECT",
          ]
          sns_destination = {
            topic_arn = var.sns_bounce_topic_arn
          }
        }

        delivery_cloudwatch = {
          enabled = true
          event_types = [
            "SEND",
            "DELIVERY",
            "RENDERING_FAILURE",
          ]
          cloudwatch_destination = {
            dimension_configurations = [
              {
                dimension_name          = "ConfigurationSet"
                dimension_value_source  = "MESSAGE_TAG"
                default_dimension_value = "transactional"
              },
              {
                dimension_name          = "EmailType"
                dimension_value_source  = "EMAIL_HEADER"
                default_dimension_value = "generic"
              },
            ]
          }
        }
      }
    }

    marketing = {
      sending_enabled            = true
      reputation_metrics_enabled = true
      suppression_reasons        = ["BOUNCE", "COMPLAINT"]
      engagement_metrics         = true
      optimized_shared_delivery  = true
      custom_redirect_domain     = "click.newsletter.example.com"
      tags = {
        Tier = "marketing"
      }

      event_destinations = {
        all_events_firehose = {
          enabled = true
          event_types = [
            "SEND",
            "DELIVERY",
            "OPEN",
            "CLICK",
            "BOUNCE",
            "COMPLAINT",
          ]
          kinesis_firehose_destination = {
            delivery_stream_arn = var.firehose_stream_arn
            iam_role_arn        = null # auto-create via create_firehose_role=true
          }
        }

        click_cloudwatch = {
          enabled = true
          event_types = [
            "OPEN",
            "CLICK",
          ]
          cloudwatch_destination = {
            dimension_configurations = [
              {
                dimension_name          = "CampaignId"
                dimension_value_source  = "MESSAGE_TAG"
                default_dimension_value = "unknown"
              },
              {
                dimension_name          = "LinkTag"
                dimension_value_source  = "LINK_TAG"
                default_dimension_value = "untagged"
              },
            ]
          }
        }
      }
    }

    default = {
      sending_enabled            = true
      reputation_metrics_enabled = true
      suppression_reasons        = ["BOUNCE", "COMPLAINT"]
      engagement_metrics         = false
      optimized_shared_delivery  = false
      custom_redirect_domain     = null
      tags = {
        Tier = "default"
      }
      event_destinations = {}
    }
  }

  # ── Receipt Rule Sets ─────────────────────────────────────────────────────────

  rule_sets = {
    inbound-example-com = {
      active = true
    }
  }

  # ── Receipt Rules ─────────────────────────────────────────────────────────────

  receipt_rules = {
    store_and_notify = {
      rule_set_name = "inbound-example-com"
      recipients    = ["inbound@example.com", "support@example.com"]
      enabled       = true
      scan_enabled  = true
      tls_policy    = "Require"
      after         = null

      s3_actions = [
        {
          bucket_name = var.inbound_bucket_name
          key_prefix  = "inbound/"
          kms_key_arn = null
          position    = 1
        },
      ]

      sns_actions = [
        {
          topic_arn = var.sns_inbound_topic_arn
          position  = 2
        },
      ]

      lambda_actions = [
        {
          function_arn    = var.inbound_processor_lambda_arn
          invocation_type = "Event"
          position        = 3
        },
      ]

      bounce_actions     = []
      stop_actions       = []
      workmail_actions   = []
      add_header_actions = []
    }

    spam_filter = {
      rule_set_name = "inbound-example-com"
      recipients    = ["inbound@example.com"]
      enabled       = true
      scan_enabled  = true
      tls_policy    = "Optional"
      after         = "store_and_notify"

      s3_actions     = []
      sns_actions    = []
      lambda_actions = []

      bounce_actions = [
        {
          message         = "Message rejected as spam."
          sender          = "mailer-daemon@example.com"
          smtp_reply_code = "550"
          status_code     = "5.1.1"
          topic_arn       = null
          position        = 1
        },
      ]

      stop_actions = [
        {
          scope     = "RuleSet"
          topic_arn = null
          position  = 2
        },
      ]

      workmail_actions   = []
      add_header_actions = []
    }
  }

  # ── Email Templates ───────────────────────────────────────────────────────────

  templates = {
    welcome = {
      subject   = "Welcome to {{company_name}}, {{first_name}}!"
      html_part = <<-HTML
        <html>
          <body>
            <h1>Welcome, {{first_name}}!</h1>
            <p>Thank you for joining {{company_name}}. Your account is ready.</p>
            <p><a href="{{login_url}}">Log in now</a></p>
          </body>
        </html>
      HTML
      text_part = "Welcome, {{first_name}}! Thank you for joining {{company_name}}. Log in at: {{login_url}}"
    }

    password_reset = {
      subject   = "Reset your {{company_name}} password"
      html_part = <<-HTML
        <html>
          <body>
            <h1>Password Reset</h1>
            <p>Hi {{first_name}},</p>
            <p>Click the link below to reset your password. This link expires in {{expiry_minutes}} minutes.</p>
            <p><a href="{{reset_url}}">Reset Password</a></p>
            <p>If you did not request a password reset, ignore this email.</p>
          </body>
        </html>
      HTML
      text_part = "Hi {{first_name}}, reset your password at: {{reset_url}} (expires in {{expiry_minutes}} minutes)"
    }

    invoice = {
      subject   = "Your {{company_name}} invoice #{{invoice_number}} for {{amount}}"
      html_part = <<-HTML
        <html>
          <body>
            <h1>Invoice #{{invoice_number}}</h1>
            <p>Hi {{first_name}},</p>
            <p>Amount due: <strong>{{amount}}</strong></p>
            <p>Due date: {{due_date}}</p>
            <p><a href="{{invoice_url}}">View Invoice</a></p>
          </body>
        </html>
      HTML
      text_part = "Invoice #{{invoice_number}} | Amount: {{amount}} | Due: {{due_date}} | View: {{invoice_url}}"
    }
  }

  # ── IAM ───────────────────────────────────────────────────────────────────────

  create_firehose_role  = true
  create_s3_role        = true
  firehose_role_name    = "ses-firehose-delivery-role-prod"
  s3_role_name          = "ses-s3-inbound-role-prod"
  sending_identity_arns = []

  tags = var.tags
}
