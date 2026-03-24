# ---------------------------------------------------------------------------
# Glue Triggers
# ---------------------------------------------------------------------------

resource "aws_glue_trigger" "this" {
  for_each = var.create_triggers ? var.triggers : {}

  name          = "${var.name_prefix}${each.key}"
  type          = each.value.type
  description   = each.value.description
  workflow_name = each.value.workflow_name
  schedule      = each.value.schedule
  enabled       = each.value.enabled != null ? each.value.enabled : true

  # start_on_creation applies only to SCHEDULED triggers
  start_on_creation = each.value.type == "SCHEDULED" ? (
    each.value.start_on_creation != null ? each.value.start_on_creation : true
  ) : null

  # ---- Actions -----------------------------------------------------------
  dynamic "actions" {
    for_each = each.value.actions
    content {
      job_name               = actions.value.job_name
      crawler_name           = actions.value.crawler_name
      arguments              = actions.value.arguments != null ? actions.value.arguments : {}
      timeout                = actions.value.timeout
      security_configuration = actions.value.security_configuration

      dynamic "notification_property" {
        for_each = actions.value.notification_property != null ? [actions.value.notification_property] : []
        content {
          notify_delay_after = notification_property.value.notify_delay_after
        }
      }
    }
  }

  # ---- Predicate (CONDITIONAL triggers) ----------------------------------
  dynamic "predicate" {
    for_each = each.value.predicate != null ? [each.value.predicate] : []
    content {
      logical = predicate.value.logical != null ? predicate.value.logical : "AND"

      dynamic "conditions" {
        for_each = predicate.value.conditions
        content {
          job_name         = conditions.value.job_name
          crawler_name     = conditions.value.crawler_name
          state            = conditions.value.state
          crawl_state      = conditions.value.crawl_state
          logical_operator = conditions.value.logical_operator != null ? conditions.value.logical_operator : "EQUALS"
        }
      }
    }
  }

  # ---- Event batching condition (EVENT triggers) -------------------------
  dynamic "event_batching_condition" {
    for_each = each.value.event_batching_condition != null ? [each.value.event_batching_condition] : []
    content {
      batch_size   = event_batching_condition.value.batch_size
      batch_window = event_batching_condition.value.batch_window
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}${each.key}" })

  depends_on = [
    aws_glue_job.this,
    aws_glue_crawler.this,
    aws_glue_workflow.this,
  ]
}
