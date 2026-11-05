output "template_ids" {
  value = { for key, experiment in module.fis_experiment : key => experiment.id }
}
