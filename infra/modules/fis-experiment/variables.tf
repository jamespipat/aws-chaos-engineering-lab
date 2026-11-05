variable "description" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "action_name" {
  type = string
}

variable "action_id" {
  type = string
}

variable "action_parameters" {
  type = map(string)
}

variable "target_name" {
  type = string
}

variable "target_resource_type" {
  type = string
}

variable "selection_mode" {
  type = string

  validation {
    condition     = var.target_resource_type != "aws:eks:pod" || var.selection_mode == "COUNT(1)"
    error_message = "EKS pod experiments must use selection mode COUNT(1)."
  }
}

variable "target_parameters" {
  type = map(string)

  validation {
    condition     = var.target_resource_type != "aws:eks:pod" || try(var.target_parameters["selectorType"], "") == "podName"
    error_message = "EKS pod experiments must select one pod by podName. deploymentName selects every pod in the deployment."
  }
}

variable "stop_condition_arns" {
  type = list(string)

  validation {
    condition     = length(var.stop_condition_arns) > 0
    error_message = "An experiment needs at least one CloudWatch alarm stop condition."
  }
}

variable "log_group_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}
