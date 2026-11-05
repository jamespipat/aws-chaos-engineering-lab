module "fis_access" {
  source = "../../../modules/fis-access"

  namespace = local.platform.namespace
}

module "admin_job" {
  source   = "../../../modules/admin-job"
  for_each = local.admin_jobs

  name                 = each.key
  namespace            = local.platform.namespace
  image                = var.app_image
  command              = each.value.command
  role_arn             = local.platform.workload_identities[each.key == "verify" ? "verifier" : each.key].role_arn
  service_account_name = each.value.service_account_name
  env                  = each.value.env
  wait_for_completion  = each.value.wait_for_completion

  depends_on = [module.fis_access]
}

module "stateless_service" {
  source   = "../../../modules/stateless-service"
  for_each = local.services

  name                 = each.key
  namespace            = local.platform.namespace
  image                = var.app_image
  command              = each.value.command
  replicas             = each.value.replicas
  role_arn             = local.platform.workload_identities[each.key].role_arn
  service_account_name = each.value.service_account_name
  env                  = each.value.env
  requests_cpu         = each.value.requests_cpu
  requests_memory      = each.value.requests_memory
  limits_cpu           = each.value.limits_cpu
  limits_memory        = each.value.limits_memory
  pdb_min_available    = each.value.pdb_min_available
  service              = each.value.service

  depends_on = [module.fis_access, module.admin_job]
}

module "load_generator" {
  source = "../../../modules/load-generator"

  namespace = local.platform.namespace
  image     = var.k6_image
  replicas  = var.load_replicas
  script    = file("${path.module}/../../../../load/k6/loan-requests.js")
  env = {
    BASE_URL    = "http://${local.platform.alb_dns_name}"
    JOURNAL_URL = "http://collector.${local.platform.namespace}.svc:8080/v1/journal"
    RATE        = "5"
    DURATION    = var.load_duration
    RUN_ID      = var.run_id
  }

  depends_on = [module.fis_access]
}

module "log_shipper" {
  source = "../../../modules/log-shipper"

  namespace      = local.platform.namespace
  role_arn       = local.platform.workload_identities["log_shipper"].role_arn
  region         = var.region
  log_group_name = local.platform.log_group_names.application

  depends_on = [module.fis_access]
}
