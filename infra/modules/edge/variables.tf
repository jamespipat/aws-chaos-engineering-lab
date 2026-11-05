variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "autoscaling_group_names" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}
