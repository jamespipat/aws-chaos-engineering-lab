output "vpc_id" {
  value = module.vpc.vpc_id
}

output "availability_zone_ids" {
  value = { for key, zone in data.aws_availability_zone.selected : key => zone.zone_id }
}

output "app_subnet_ids" {
  value = { for index, key in local.ordered_keys : key => module.vpc.private_subnets[index] }
}

output "data_subnet_ids" {
  value = { for index, key in local.ordered_keys : key => module.vpc.database_subnets[index] }
}

output "app_subnet_id_list" {
  value = [for key in local.ordered_keys : module.vpc.private_subnets[index(local.ordered_keys, key)]]
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}
