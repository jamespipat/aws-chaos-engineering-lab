provider "aws" {
  region              = var.region
  allowed_account_ids = [var.allowed_account_id]

  default_tags {
    tags = local.tags
  }
}
