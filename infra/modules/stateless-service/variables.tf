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

variable "replicas" {
  type = number
}

variable "role_arn" {
  type    = string
  default = null
}

variable "service_account_name" {
  type = string
}

variable "env" {
  type = map(string)
}

variable "port" {
  type    = number
  default = 8080
}

variable "requests_cpu" {
  type = string
}

variable "requests_memory" {
  type = string
}

variable "limits_cpu" {
  type = string
}

variable "limits_memory" {
  type = string
}

variable "pdb_min_available" {
  type    = number
  default = null
}

variable "service" {
  type = object({
    type      = string
    port      = number
    node_port = optional(number)
  })
  default = null
}
