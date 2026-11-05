terraform {
  required_version = "1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}
