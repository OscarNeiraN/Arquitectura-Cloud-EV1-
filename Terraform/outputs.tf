output "app_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "URL del catalogo FreshBox a traves del ALB"
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "ecr_repository_urls" {
  value       = { for k, v in module.ecr : k => v.repository_url }
  description = "URLs de los 5 repositorios ECR"
}

output "asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "Auto Scaling Group de la capa App"
}

output "mysql_private_ip" {
  value       = module.database.db_address
  description = "IP privada de la EC2 MySQL (capa Data)"
}

output "backup_plan_id" {
  value       = module.backup.backup_plan_id
  description = "Plan de AWS Backup de la EC2 MySQL"
}
