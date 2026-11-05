resource "kubernetes_service_account_v1" "k6" {
  metadata {
    name      = "k6"
    namespace = var.namespace
  }
}

resource "kubernetes_config_map_v1" "script" {
  metadata {
    name      = "k6-loan-requests"
    namespace = var.namespace
  }
  data = {
    "loan-requests.js" = var.script
  }
}

resource "kubernetes_deployment_v1" "k6" {
  metadata {
    name      = "k6"
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "k6"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "k6"
        }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.k6.metadata[0].name
        container {
          name              = "k6"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          args              = ["run", "/scripts/loan-requests.js"]
          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "1"
              memory = "512Mi"
            }
          }
          volume_mount {
            name       = "script"
            mount_path = "/scripts"
            read_only  = true
          }
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map_v1.script.metadata[0].name
          }
        }
      }
    }
  }
}
