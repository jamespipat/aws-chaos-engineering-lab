resource "aws_cloudwatch_log_group" "application" {
  name              = "/${var.name_prefix}/application"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "fis" {
  name              = "/${var.name_prefix}/fis"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "symptom" {
  for_each = var.alarms

  alarm_name          = "${var.name_prefix}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = "ChaosLab"
  period              = 60
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data
  alarm_description   = each.value.stop_condition ? "FIS safety stop" : "Detection signal, not a FIS stop condition"
  tags                = var.tags
}

resource "aws_cloudwatch_dashboard" "lab" {
  dashboard_name = var.name_prefix
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Logical success and errors"
          region = data.aws_region.current.region
          metrics = [
            ["ChaosLab", "LogicalRequests"],
            ["ChaosLab", "LogicalSuccesses"],
            ["ChaosLab", "LogicalErrorRate"],
          ]
          stat   = "Sum"
          period = 60
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Logical p95"
          region = data.aws_region.current.region
          metrics = [
            ["ChaosLab", "LogicalP95Milliseconds"],
          ]
          stat   = "Average"
          period = 60
        }
      }
    ]
  })
}

data "aws_region" "current" {}
