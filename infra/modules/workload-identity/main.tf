module "role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.8.2"

  name                 = var.name
  use_name_prefix      = false
  permissions_boundary = var.permissions_boundary_arn
  create_policy        = true
  permissions          = var.permissions

  oidc_providers = {
    this = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account_name}"]
    }
  }

  tags = var.tags
}
