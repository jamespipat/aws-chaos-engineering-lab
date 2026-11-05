output "dns_name" {
  value = module.alb.dns_name
}

output "target_group_arn" {
  value = module.alb.target_groups["api"].arn
}

output "listener_arn" {
  value = module.alb.listeners["http"].arn
}
