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

variable "environment" {
  type        = string
  description = "Value for the Environment tag."
  default     = "lab"
}

variable "state_bucket" {
  type        = string
  description = "Bootstrap state bucket name. Set this after the bootstrap apply."
}

variable "availability_zone_names" {
  type        = map(string)
  description = "Two distinct AZ names in the selected Region, keyed az_a and az_b."

  validation {
    condition     = toset(keys(var.availability_zone_names)) == toset(["az_a", "az_b"]) && length(toset(values(var.availability_zone_names))) == 2
    error_message = "availability_zone_names needs exactly az_a and az_b with two different AZ names."
  }
}

variable "operator_cidr" {
  type        = string
  description = "Your public IPv4 address as a /32. It is the only address allowed to call the EKS API."

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/32$", var.operator_cidr))
    error_message = "operator_cidr must be a single IPv4 address in /32 form."
  }
}

variable "budget_notification_email" {
  type        = string
  description = "Email address for the 25, 50, and 80 percent budget notifications."

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+$", var.budget_notification_email))
    error_message = "budget_notification_email must be an email address."
  }
}

variable "instance_type" {
  type    = string
  default = "m6i.large"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL minor pinned before the reviewed plan."
  default     = "17.11"
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "log_retention_days" {
  type    = number
  default = 1
}

variable "budget_limit_usd" {
  type    = number
  default = 50
}

variable "detection_p95_ms" {
  type        = number
  description = "Replace with the measured baseline p95 plus 50 after the baseline run. This alarm does not stop FIS."
  default     = 750
}
