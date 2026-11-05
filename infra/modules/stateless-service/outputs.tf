output "service_name" {
  value = var.service == null ? null : kubernetes_service_v1.this[0].metadata[0].name
}
