variable "vpc_cidr" {}
variable "project_name" {}

variable "subnet_newbits" {
  type        = number
  description = "Bits adicionales sobre vpc_cidr para calcular cada subred (cidrsubnet newbits). Ej: VPC /16 -> 8 da subredes /24; VPC /22 -> 4 da subredes /26."
  default     = 8
}

variable "subnets_config" {
  type = map(object({
    az      = string
    net_num = number
    public  = bool
    tier    = optional(string)
  }))
}

variable "enable_network" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}
