variable "region" {
  type        = string
  description = "AWS Region for the lab, for example us-west-2."
}

variable "allowed_account_id" {
  type        = string
  description = "The only AWS account ID this root may change."

  validation {
    condition     = can(regex("^[0-9]{12}$", var.allowed_account_id))
    error_message = "allowed_account_id must be a 12-digit AWS account ID."
  }
}

variable "state_bucket" {
  type = string
}

variable "app_image" {
  type        = string
  description = "Immutable application image, including the digest."
}

variable "k6_image" {
  type    = string
  default = "grafana/k6:1.7.1"
}

variable "load_replicas" {
  type    = number
  default = 0
}

variable "load_duration" {
  type    = string
  default = "40m"
}

variable "enable_verify_job" {
  type    = bool
  default = false
}

variable "run_id" {
  type    = string
  default = "pending"
}

variable "evidence_prefix" {
  type    = string
  default = "journal/pending"
}
