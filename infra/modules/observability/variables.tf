variable "name_prefix" {
  type = string
}

variable "log_retention_days" {
  type = number
}

variable "alarms" {
  type = map(object({
    metric_name         = string
    comparison_operator = string
    threshold           = number
    evaluation_periods  = number
    statistic           = string
    treat_missing_data  = string
    stop_condition      = bool
  }))
}

variable "tags" {
  type = map(string)
}
