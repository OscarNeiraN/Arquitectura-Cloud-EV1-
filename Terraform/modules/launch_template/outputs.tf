output "launch_template_id" {
  description = "ID de la launch template creada"
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "ARN de la launch template creada"
  value       = aws_launch_template.this.arn
}

output "launch_template_name" {
  description = "Nombre de la launch template creada"
  value       = aws_launch_template.this.name
}

output "launch_template_latest_version" {
  description = "Versión más reciente de la launch template"
  value       = aws_launch_template.this.latest_version
}