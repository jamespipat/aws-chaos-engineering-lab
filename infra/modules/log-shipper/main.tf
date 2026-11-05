resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = "log-shipper"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.role_arn
    }
  }
}

resource "helm_release" "this" {
  name       = "log-shipper"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = var.chart_version
  namespace  = var.namespace

  depends_on = [kubernetes_service_account_v1.this]

  values = [yamlencode({
    serviceAccount = {
      create = false
      name   = kubernetes_service_account_v1.this.metadata[0].name
    }
    cloudWatch = {
      enabled = false
    }
    cloudWatchLogs = {
      enabled         = true
      region          = var.region
      logGroupName    = var.log_group_name
      logStreamPrefix = "fluentbit-"
      autoCreateGroup = false
    }
    firehose = {
      enabled = false
    }
    kinesis = {
      enabled = false
    }
    elasticsearch = {
      enabled = false
    }
  })]
}
