variable "name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "alarm_arns" {
  type = list(string)
}

variable "log_group_arn" {
  type = string
}

variable "permissions_boundary_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}
