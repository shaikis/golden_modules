# ── SES Email Templates ────────────────────────────────────────────────────────

resource "aws_ses_template" "this" {
  for_each = var.create_templates ? var.templates : {}

  name    = each.key
  subject = each.value.subject
  html    = each.value.html_part
  text    = each.value.text_part
}
