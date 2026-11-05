variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_group_name" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "multi_az" {
  type = bool
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "tags" {
  type = map(string)
}
