locals {
  labels = {
    "app.kubernetes.io/name"      = var.name
    "app.kubernetes.io/part-of"   = "aws-chaos-lab"
    "app.kubernetes.io/component" = var.command
  }
}

resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = var.role_arn == null ? {} : {
      "eks.amazonaws.com/role-arn" = var.role_arn
    }
    labels = local.labels
  }
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = local.labels
    }
    template {
      metadata {
        labels = local.labels
      }
      spec {
        service_account_name = kubernetes_service_account_v1.this.metadata[0].name
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "topology.kubernetes.io/zone"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = local.labels
          }
        }
        container {
          name              = "app"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          command           = ["node", "--experimental-strip-types", "src/main.ts"]
          args              = [var.command]
          port {
            container_port = var.port
          }
          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
          env {
            name  = "PORT"
            value = tostring(var.port)
          }
          resources {
            requests = {
              cpu    = var.requests_cpu
              memory = var.requests_memory
            }
            limits = {
              cpu    = var.limits_cpu
              memory = var.limits_memory
            }
          }
          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
          startup_probe {
            http_get {
              path = "/healthz"
              port = var.port
            }
            failure_threshold = 30
            period_seconds    = 2
          }
          readiness_probe {
            http_get {
              path = "/readyz"
              port = var.port
            }
            period_seconds = 5
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = var.port
            }
            period_seconds = 10
          }
        }
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  count = var.service == null ? 0 : 1

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    type     = var.service.type
    selector = local.labels
    port {
      port        = var.service.port
      target_port = var.port
      node_port   = var.service.type == "NodePort" ? var.service.node_port : null
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "this" {
  count = var.pdb_min_available == null ? 0 : 1

  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    min_available = var.pdb_min_available
    selector {
      match_labels = local.labels
    }
  }
}
