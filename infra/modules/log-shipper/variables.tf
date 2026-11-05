variable "namespace" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "region" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "0.2.0"
}
