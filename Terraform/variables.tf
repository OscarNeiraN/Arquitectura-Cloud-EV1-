variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto. Los repositorios ECR se llaman <project_name>-<servicio> (deben coincidir con ecr-push.sh)."
}

variable "environment" {
  type        = string
  description = "Ambiente. Se antepone al nombre de los recursos (<environment>-<project_name>-...) y se usa en el tag Environment."
}

# --- Red ----------------------------------------------------------------------
variable "vpc_cidr" {
  type = string
}

variable "subnet_newbits" {
  type        = number
  description = "Bits adicionales sobre vpc_cidr para cada subred. VPC /22 -> 4 da subredes /26."
  default     = 4
}

variable "subnets_config" {
  type = map(object({
    az      = string
    net_num = number
    public  = bool
    tier    = optional(string)
  }))
  description = "Subredes de la VPC. tier: public, app o db."
}

# --- Computo ------------------------------------------------------------------
variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2 para las capas App y Data."
  default     = "t4g.small"
}

variable "ec2_instance_profile_name" {
  type        = string
  description = "Instance profile IAM asociado a las EC2. Habilita AWS Systems Manager (Session Manager) y la lectura de Amazon ECR, sin necesidad de SSH. En AWS Academy Learner Lab es LabInstanceProfile."
}

variable "ami_config" {
  type = object({
    most_recent = bool
    owners      = list(string)
    filters = list(object({
      name   = string
      values = list(string)
    }))
  })
}

variable "root_volume_size" {
  type        = number
  description = "Tamano en GB del volumen EBS (cifrado) de las EC2 App."
  default     = 20
}

variable "asg_min_size" {
  type        = number
  description = "Instancias minimas (y deseadas) del Auto Scaling Group."
  default     = 2
}

variable "asg_max_size" {
  type        = number
  description = "Instancias maximas del Auto Scaling Group."
  default     = 4
}

# --- Contenedores y ALB -------------------------------------------------------
variable "container_services" {
  type = map(object({
    port     = number
    frontend = optional(bool, false)
  }))
  description = "Contenedores de cada EC2 App. Cada clave es el repositorio ECR <project_name>-<clave> y el nombre del contenedor (upstream de nginx.conf)."
}

variable "alb_config" {
  type = object({
    name     = string
    internal = optional(bool, false)
  })
}

# --- Base de datos ------------------------------------------------------------
variable "db_config" {
  type = object({
    db_name  = optional(string, "freshbox")
    username = string
    password = string
  })
  sensitive = true
}
