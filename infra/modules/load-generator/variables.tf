variable "namespace" {
  type = string
}

variable "image" {
  type = string
}

variable "replicas" {
  type = number
}

variable "script" {
  type = string
}

variable "env" {
  type = map(string)
}
