variable "enable_backup" {
  type        = bool
  description = "Habilita AWS Backup."
  default     = true
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto."
}

variable "aws_region" {
  type        = string
  description = "Region de AWS."
}

variable "backup_retention_days" {
  type        = number
  description = "Dias de retencion de los recovery points."
  default     = 7
}

variable "backup_schedule_expression" {
  type        = string
  description = "Expresion cron/rate de AWS Backup en UTC."
  default     = "cron(0 5 * * ? *)"
}

variable "backup_service_role_arn" {
  type        = string
  description = "ARN de un rol existente para AWS Backup."
  default     = ""
}

variable "enable_backup_selections" {
  type        = bool
  description = "Asocia recursos al plan de AWS Backup. Requiere que el rol indicado pueda pasarse a AWS Backup."
  default     = false
}

variable "enable_ec2_backup_selection" {
  type        = bool
  description = "Crea la seleccion de AWS Backup para instancias EC2 etiquetadas."
  default     = true
}

variable "ec2_selection_tag_key" {
  type        = string
  description = "Tag usado para seleccionar instancias EC2."
  default     = "Backup"
}

variable "ec2_selection_tag_value" {
  type        = string
  description = "Valor del tag usado para seleccionar instancias EC2."
  default     = "daily"
}

variable "start_window_minutes" {
  type        = number
  description = "Ventana de inicio del backup, en minutos."
  default     = 60
}

variable "completion_window_minutes" {
  type        = number
  description = "Ventana maxima de ejecucion del backup, en minutos."
  default     = 180
}
