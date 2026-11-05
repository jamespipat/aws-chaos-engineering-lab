locals {
  # terraform-aws-modules/vpc/aws 6.7.3 addresses subnets with count.
  # sort() matches the validation sequence, so index 0 stays az_a.
  ordered_keys = sort(keys(var.availability_zones))
  zones        = [for key in local.ordered_keys : var.availability_zones[key]]
}

data "aws_availability_zone" "selected" {
  for_each = var.availability_zones
  name     = each.value.availability_zone
}

data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = var.name
  cidr = var.cidr_block

  azs              = [for zone in local.zones : zone.availability_zone]
  public_subnets   = [for zone in local.zones : zone.nat_cidr]
  private_subnets  = [for zone in local.zones : zone.app_cidr]
  database_subnets = [for zone in local.zones : zone.data_cidr]

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = false

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = distinct(concat(module.vpc.private_route_table_ids, module.vpc.database_route_table_ids))
  tags              = merge(var.tags, { Name = "${var.name}-s3" })
}
