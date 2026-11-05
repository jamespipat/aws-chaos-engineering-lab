variable "name_prefix" {
  type = string
}

variable "purpose" {
  type = string
}

variable "force_destroy" {
  type = bool
}

variable "expire_days" {
  type    = number
  default = null
}

variable "tags" {
  type = map(string)
}
