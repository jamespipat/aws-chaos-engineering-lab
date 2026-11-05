variable "name" {
  type = string
}

variable "limit_usd" {
  type = number
}

variable "notification_email" {
  type = string
}

variable "tags" {
  type = map(string)
}
