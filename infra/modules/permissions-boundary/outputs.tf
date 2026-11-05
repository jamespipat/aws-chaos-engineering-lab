output "arn" {
  description = "Permissions boundary for lab-created workload and FIS roles."
  value       = aws_iam_policy.this.arn
}
