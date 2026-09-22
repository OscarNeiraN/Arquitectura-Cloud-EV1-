variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "enable_alb" {
  type    = bool
  default = true
}

variable "alb_config" {
  type = object({
    name     = string
    internal = bool
  })
}

variable "listeners" {
  description = "Mapa de listeners/target groups del ALB. Cada entrada crea un listener y un target group en el mismo puerto, reenviando trafico a target_instance_ids."
  type = map(object({
    port              = number
    protocol          = optional(string, "HTTP")
    health_check_path = optional(string, "/")
  }))
}

variable "target_instance_ids" {
  description = "Mapa nombre-legible => instance_id de las EC2 a registrar en cada target group del ALB. Las claves deben ser conocidas en plan; los valores pueden resolverse en apply."
  type        = map(string)
  default     = {}
}
