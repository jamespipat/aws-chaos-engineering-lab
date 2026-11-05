resource "aws_fis_experiment_template" "this" {
  description = var.description
  role_arn    = var.role_arn
  tags        = var.tags

  experiment_options {
    account_targeting            = "single-account"
    empty_target_resolution_mode = "fail"
  }

  dynamic "stop_condition" {
    for_each = var.stop_condition_arns
    content {
      source = "aws:cloudwatch:alarm"
      value  = stop_condition.value
    }
  }

  action {
    name      = var.action_name
    action_id = var.action_id

    dynamic "parameter" {
      for_each = var.action_parameters
      content {
        key   = parameter.key
        value = parameter.value
      }
    }

    target {
      key   = var.target_name
      value = "lab-target"
    }
  }

  target {
    name           = "lab-target"
    resource_type  = var.target_resource_type
    selection_mode = var.selection_mode
    parameters     = var.target_parameters
  }

  log_configuration {
    log_schema_version = "2"
    cloudwatch_logs_configuration {
      log_group_arn = endswith(var.log_group_arn, ":*") ? var.log_group_arn : "${var.log_group_arn}:*"
    }
  }
}
