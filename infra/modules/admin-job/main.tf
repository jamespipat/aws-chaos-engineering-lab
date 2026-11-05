resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.role_arn
    }
  }
}

resource "kubernetes_job_v1" "this" {
  wait_for_completion = var.wait_for_completion

  timeouts {
    create = "15m"
  }

  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    backoff_limit              = 1
    ttl_seconds_after_finished = 86400
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = var.name
        }
      }
      spec {
        restart_policy       = "Never"
        service_account_name = kubernetes_service_account_v1.this.metadata[0].name
        container {
          name              = "task"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          command           = ["node", "--experimental-strip-types", "src/main.ts"]
          args              = [var.command]
          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
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
        }
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}
