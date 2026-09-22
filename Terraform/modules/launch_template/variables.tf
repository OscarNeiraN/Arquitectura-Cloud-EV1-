variable "project_name" {
  type        = string
  description = "Nombre del proyecto para etiquetado"
}

variable "name_prefix" {
  type        = string
  description = "Prefijo para el nombre de la launch template"
  default     = "lt"
}

variable "ami_id" {
  type        = string
  description = "ID de la AMI a usar en las instancias"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2 (ej: t2.micro, t3.small)"
}

variable "key_name" {
  type        = string
  description = "Nombre del par de claves SSH"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Lista de IDs de grupos de seguridad"
  default     = []
}

variable "iam_instance_profile_name" {
  type        = string
  description = "Nombre del instance profile IAM para la instancia"
  default     = null
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Asociar IP pública automáticamente"
  default     = false
}

variable "user_data" {
  type        = string
  description = "Script de inicialización (base64 encoded)"
  default     = null
}

variable "user_data_file" {
  type        = string
  description = "Ruta al archivo de user data (relativa al directorio raíz del proyecto)"
  default     = null
}

variable "monitoring" {
  type        = bool
  description = "Habilitar monitoreo detallado"
  default     = false
}

variable "ebs_optimized" {
  type        = bool
  description = "Optimizar para EBS"
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  type        = string
  description = "Comportamiento al apagar instancia"
  default     = "terminate"
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "El valor debe ser 'stop' o 'terminate'."
  }
}

variable "root_device_name" {
  type        = string
  description = "Nombre del dispositivo raiz definido por la AMI."
}

variable "root_volume_size" {
  type        = number
  description = "Tamano en GB del volumen raiz EBS."
  default     = 50
}

variable "root_volume_type" {
  type        = string
  description = "Tipo del volumen raiz EBS."
  default     = "gp3"
}

variable "root_volume_encrypted" {
  type        = bool
  description = "Cifra el volumen raiz EBS."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas adicionales para la launch template"
  default     = {}
}
