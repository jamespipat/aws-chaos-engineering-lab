variable "name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "vpc_id" {
  type = string
}

variable "default_vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_groups" {
  type = map(object({
    subnet_id         = string
    instance_type     = string
    availability_zone = string
  }))
}

variable "fis_role_arn" {
  type = string
}

variable "endpoint_public_access_cidrs" {
  type = list(string)
}

variable "fargate_profiles" {
  type    = map(any)
  default = {}

  validation {
    condition     = length(var.fargate_profiles) == 0
    error_message = "This platform does not run Fargate."
  }
}

variable "tags" {
  type = map(string)
}
