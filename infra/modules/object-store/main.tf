resource "random_id" "suffix" {
  byte_length = 4

  keepers = {
    purpose = var.purpose
  }
}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.17.0"

  bucket        = "${var.name_prefix}-${var.purpose}-${random_id.suffix.hex}"
  force_destroy = var.force_destroy

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = true
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true

  lifecycle_rule = var.expire_days == null ? [] : [{
    id      = "expire"
    enabled = true
    expiration = {
      days = var.expire_days
    }
  }]

  tags = var.tags
}
