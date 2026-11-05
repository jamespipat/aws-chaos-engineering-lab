provider "aws" {
  region              = var.region
  allowed_account_ids = [var.allowed_account_id]
}

data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket       = var.state_bucket
    key          = "aws-chaos-lab/lab/foundation/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}

locals {
  platform = data.terraform_remote_state.foundation.outputs.platform
}
