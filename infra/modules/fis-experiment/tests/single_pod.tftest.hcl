mock_provider "aws" {}

run "eks_pod_experiment_selects_one_pod_by_name" {
  command = plan

  variables {
    description = "Delete one API pod"
    role_arn    = "arn:aws:iam::000000000000:role/aws-chaos-lab-fis"
    action_name = "delete"
    action_id   = "aws:eks:pod-delete"
    action_parameters = {
      kubernetesServiceAccount = "fis-experiment"
      gracePeriodSeconds       = "0"
    }
    target_name          = "Pods"
    target_resource_type = "aws:eks:pod"
    selection_mode       = "COUNT(1)"
    target_parameters = {
      clusterIdentifier = "aws-chaos-lab"
      namespace         = "aws-chaos-lab"
      selectorType      = "podName"
      selectorValue     = "pending-target-preview"
    }
    stop_condition_arns = ["arn:aws:cloudwatch:us-west-2:000000000000:alarm:safety"]
    log_group_arn       = "arn:aws:logs:us-west-2:000000000000:log-group:/aws-chaos-lab/fis"
    tags                = { Project = "aws-chaos-lab" }
  }

  assert {
    condition = alltrue([
      for target in aws_fis_experiment_template.this.target :
      target.parameters["selectorType"] == "podName" && target.selection_mode == "COUNT(1)"
    ])
    error_message = "The pod experiment must select one pod by name."
  }
}
