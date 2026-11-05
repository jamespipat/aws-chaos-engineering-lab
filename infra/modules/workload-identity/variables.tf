variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "permissions_boundary_arn" {
  type = string
}

variable "permissions" {
  type = map(object({
    sid       = optional(string)
    actions   = optional(list(string))
    effect    = optional(string, "Allow")
    resources = optional(list(string))
    condition = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
}

variable "tags" {
  type = map(string)
}
