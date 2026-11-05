check "not_default_vpc" {
  assert {
    condition     = var.vpc_id != var.default_vpc_id
    error_message = "Refusing to place the cluster in the default VPC."
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  authentication_mode          = "API"

  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = false

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    for key, group in var.node_groups : key => {
      name           = "${var.name}-${key}"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [group.instance_type]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      subnet_ids     = [group.subnet_id]
      labels         = { "topology.kubernetes.io/zone" = group.availability_zone }
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }

  access_entries = {
    fis = {
      principal_arn = var.fis_role_arn
      user_name     = "fis-experiment"
      type          = "STANDARD"
    }
  }

  tags = var.tags
}
