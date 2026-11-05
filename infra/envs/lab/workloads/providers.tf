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
  eks_token_args = [
    "eks", "get-token",
    "--cluster-name", local.platform.cluster_name,
    "--region", var.region,
  ]
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.allowed_account_id]
}

provider "kubernetes" {
  host                   = local.platform.cluster_endpoint
  cluster_ca_certificate = base64decode(local.platform.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = local.eks_token_args
  }
}

provider "helm" {
  kubernetes = {
    host                   = local.platform.cluster_endpoint
    cluster_ca_certificate = base64decode(local.platform.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = local.eks_token_args
    }
  }
}
