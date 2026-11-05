terraform {
  required_version = "1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
  }

  backend "s3" {
    key          = "aws-chaos-lab/lab/experiments/terraform.tfstate"
    use_lockfile = true
  }
}
