variable "db_config" {}
variable "subnet_id" {}
variable "security_group_id" {}

variable "create_db" {
  type    = bool
  default = true
}

variable "project_name" {
  type = string
}

variable "ami_id" {
  type        = string
  description = "AMI (Amazon Linux 2023 ARM) para la instancia EC2 MySQL."
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia para el EC2 MySQL."
  default     = "t4g.micro"
}

variable "iam_instance_profile_name" {
  type        = string
  description = "Instance profile IAM para la instancia EC2 MySQL."
  default     = null
}

variable "user_data_template_path" {
  type        = string
  description = "Plantilla (templatefile) del user data de la EC2 MySQL. Recibe db_name, db_user, db_password e init_sql. Si es null se usa la plantilla por defecto del proyecto raiz."
  default     = null
}

variable "init_sql_path" {
  type        = string
  description = "Script SQL que se entrega a la plantilla como init_sql. Si es null se usa la ruta por defecto del proyecto raiz."
  default     = null
}
