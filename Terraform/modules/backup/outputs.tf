output "backup_vault_name" {
  value = try(aws_backup_vault.this[0].name, null)
}

output "backup_plan_id" {
  value = try(aws_backup_plan.this[0].id, null)
}

output "backup_service_role_arn" {
  value = local.backup_role_arn
}

output "backup_selections_enabled" {
  value = var.enable_backup_selections
}

output "ec2_selection_id" {
  value = try(aws_backup_selection.ec2[0].id, null)
}
