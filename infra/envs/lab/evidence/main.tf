module "evidence" {
  source = "../../../modules/object-store"

  name_prefix   = "aws-chaos-lab"
  purpose       = "evidence"
  force_destroy = false
  expire_days   = 30
  tags = {
    Project     = "aws-chaos-lab"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
