output "log_group_names" {
  value = {
    application = aws_cloudwatch_log_group.application.name
    fis         = aws_cloudwatch_log_group.fis.name
  }
}

output "log_group_arns" {
  value = {
    application = aws_cloudwatch_log_group.application.arn
    fis         = aws_cloudwatch_log_group.fis.arn
  }
}

output "alarm_arns" {
  value = { for key, alarm in aws_cloudwatch_metric_alarm.symptom : key => alarm.arn }
}

output "stop_condition_alarm_arns" {
  value = [for key, alarm in aws_cloudwatch_metric_alarm.symptom : alarm.arn if var.alarms[key].stop_condition]
}
