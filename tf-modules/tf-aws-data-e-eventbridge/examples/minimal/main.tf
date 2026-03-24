module "eventbridge" {
  source = "../../"

  rules = {
    daily_report = {
      schedule_expression = "cron(0 8 * * ? *)"
    }
  }

  targets = {
    daily_report_lambda = {
      rule_key = "daily_report"
      arn      = "arn:aws:lambda:eu-west-1:123456789012:function:generate-report"
    }
  }
}
