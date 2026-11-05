variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "availability_zones" {
  description = "Append-only AZ map. Keys must be az_a, then az_b, and so on."
  type = map(object({
    availability_zone = string
    app_cidr          = string
    data_cidr         = string
    nat_cidr          = string
  }))

  validation {
    condition     = keys(var.availability_zones) == tolist(slice(["az_a", "az_b", "az_c", "az_d", "az_e", "az_f"], 0, length(var.availability_zones)))
    error_message = "AZ keys must be the append-only sequence az_a, az_b, and so on. Inserting or reordering a key shifts upstream subnet indexes."
  }
}

variable "single_nat_gateway" {
  type = bool
}

variable "tags" {
  type = map(string)
}
