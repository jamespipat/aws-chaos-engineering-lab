terraform {
  required_version = "1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.3.0"
    }
  }

  backend "s3" {
    key          = "aws-chaos-lab/lab/workloads/terraform.tfstate"
    use_lockfile = true
  }
}
