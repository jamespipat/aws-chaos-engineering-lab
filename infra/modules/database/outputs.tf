output "host" {
  value = module.db.db_instance_address
}

output "port" {
  value = module.db.db_instance_port
}

output "name" {
  value = module.db.db_instance_name
}

output "resource_id" {
  value = module.db.db_instance_resource_id
}

output "master_secret_arn" {
  value = module.db.db_instance_master_user_secret_arn
}
