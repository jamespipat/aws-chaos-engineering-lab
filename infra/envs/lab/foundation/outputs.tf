output "platform" {
  value = {
    name_prefix                        = local.name_prefix
    tags                               = local.tags
    region                             = var.region
    account_id                         = data.aws_caller_identity.current.account_id
    vpc_id                             = module.network.vpc_id
    availability_zone_ids              = module.network.availability_zone_ids
    app_subnet_ids                     = module.network.app_subnet_ids
    data_subnet_ids                    = module.network.data_subnet_ids
    cluster_name                       = module.cluster.cluster_name
    cluster_endpoint                   = module.cluster.cluster_endpoint
    cluster_certificate_authority_data = module.cluster.cluster_certificate_authority_data
    oidc_provider_arn                  = module.cluster.oidc_provider_arn
    node_security_group_id             = module.cluster.node_security_group_id
    autoscaling_group_names            = module.cluster.autoscaling_group_names
    database_host                      = module.database.host
    database_port                      = module.database.port
    database_name                      = module.database.name
    database_master_secret_arn         = module.database.master_secret_arn
    database_tls_required              = true
    workload_identities = { for key, identity in module.workload_identity : key => {
      role_arn             = identity.role_arn
      namespace            = identity.namespace
      service_account_name = identity.service_account_name
    } }
    queue_url                 = module.queue.queue_url
    dlq_url                   = module.queue.dlq_url
    alb_dns_name              = module.edge.dns_name
    target_group_arn          = module.edge.target_group_arn
    listener_arn              = module.edge.listener_arn
    log_group_names           = module.observability.log_group_names
    log_group_arns            = module.observability.log_group_arns
    stop_condition_alarm_arns = module.observability.stop_condition_alarm_arns
    fis_execution_role_arn    = module.fis_execution_role.arn
    evidence_bucket_name      = data.terraform_remote_state.evidence.outputs.bucket_name
    app_repository_url        = module.registry.repository_url
    namespace                 = local.namespace
  }
}
