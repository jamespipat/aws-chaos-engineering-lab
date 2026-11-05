variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "image" {
  type = string
}

variable "command" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "env" {
  type = map(string)
}

variable "wait_for_completion" {
  type = bool
}
