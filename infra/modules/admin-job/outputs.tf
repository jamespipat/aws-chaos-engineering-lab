output "name" {
  value = kubernetes_job_v1.this.metadata[0].name
}
