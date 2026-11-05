output "name" {
  value = kubernetes_deployment_v1.k6.metadata[0].name
}
