locals {
  experiments = {
    pod_delete = {
      description = "Delete one API pod in the lab namespace."
      action_name = "delete-one-api-pod"
      action_id   = "aws:eks:pod-delete"
      action_parameters = {
        kubernetesServiceAccount = "fis-experiment"
        gracePeriodSeconds       = "0"
      }
      target_name = "Pods"
      target_parameters = {
        clusterIdentifier = local.platform.cluster_name
        namespace         = local.platform.namespace
        selectorType      = "podName"
        selectorValue     = var.pod_name
      }
    }
    db_path_latency = {
      description = "Add 100ms latency from one API pod toward the RDS hostname."
      action_name = "delay-database-path"
      action_id   = "aws:eks:pod-network-latency"
      action_parameters = {
        kubernetesServiceAccount = "fis-experiment"
        duration                 = "PT2M"
        delayMilliseconds        = "100"
        jitterMilliseconds       = "10"
        sources                  = var.latency_sources
        maxErrorsPercent         = "0"
      }
      target_name = "Pods"
      target_parameters = {
        clusterIdentifier = local.platform.cluster_name
        namespace         = local.platform.namespace
        selectorType      = "podName"
        selectorValue     = var.pod_name
      }
    }
  }
}
