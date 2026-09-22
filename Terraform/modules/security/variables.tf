variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_ingress_rules" {
  type = list(object({
    from_port = number
    to_port   = number
  }))
  description = "Rangos de puertos TCP permitidos hacia las EC2 App, con origen el SG del ALB."
  default = [
    { from_port = 80, to_port = 80 },
    { from_port = 3001, to_port = 3004 },
  ]
}
