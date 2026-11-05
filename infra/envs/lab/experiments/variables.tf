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

variable "pod_name" {
  type        = string
  description = "Current API pod name. Replace this and re-plan before each experiment preview."
  default     = "pending-target-preview"
}

variable "latency_sources" {
  type        = string
  description = "RDS endpoint hostname. Replace this before experiment B."
  default     = "pending-rds-hostname"
}
