module "fis_experiment" {
  source   = "../../../modules/fis-experiment"
  for_each = local.experiments

  description          = each.value.description
  role_arn             = local.platform.fis_execution_role_arn
  action_name          = each.value.action_name
  action_id            = each.value.action_id
  action_parameters    = each.value.action_parameters
  target_name          = each.value.target_name
  target_resource_type = "aws:eks:pod"
  selection_mode       = "COUNT(1)"
  target_parameters    = each.value.target_parameters
  stop_condition_arns  = local.platform.stop_condition_alarm_arns
  log_group_arn        = local.platform.log_group_arns.fis
  tags                 = local.platform.tags
}
