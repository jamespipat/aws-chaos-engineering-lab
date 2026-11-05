module "state" {
  source = "../modules/object-store"

  name_prefix   = "aws-chaos-lab"
  purpose       = "tfstate"
  force_destroy = true
  tags = {
    Project     = "aws-chaos-lab"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
