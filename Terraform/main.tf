# =============================================================================
# FreshBox SpA - EP1 ARY1102 Arquitectura Cloud
# Arquitectura TO-BE de 3 capas en AWS (us-east-1, Multi-AZ)
#
#   Capa 1 Web  (publica) : VPC /22, 2 subredes publicas, Internet Gateway, ALB
#   Capa 2 App  (privada) : 2 subredes privadas, NAT Gateway, ASG (min 2 / max 4) de EC2 t4g.small
#                           + Docker (5 contenedores) y Amazon ECR
#   Capa 3 Data (privada) : 2 subredes privadas, EC2 t4g.small + MySQL y AWS Backup
#   Seguridad             : Security Groups por capa (ALB -> App -> BD) y cifrado EBS
#
# Orden de despliegue (las EC2 App descargan las imagenes desde ECR al iniciar):
#   1) terraform apply "-target=module.ecr"        # crea los 5 repositorios (comillas: PowerShell)
#   2) ./desarrolloappEP1/scripts/ecr-push.sh      # build ARM64 + push de las 5 imagenes
#   3) terraform apply      




# =============================================================================

locals {
  # Prefijo de nombres de los recursos: prod-freshbox-...
  name_prefix = "${var.environment}-${var.project_name}"

  # Tags comunes: se aplican a todos los recursos via default_tags del provider
  common_tags = {
    Project     = local.name_prefix
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Subredes por capa, ordenadas por nombre: [0] = us-east-1a, [1] = us-east-1b
  app_subnet_keys  = sort(keys(module.network.app_private_subnet_ids))
  data_subnet_keys = sort(keys(module.network.db_private_subnet_ids))

  # Contenedores: un frontend (Nginx, publicado al ALB) y los 4 microservicios backend
  frontend_service = one([for name, svc in var.container_services : name if svc.frontend])
  backend_services = { for name, svc in var.container_services : name => svc.port if !svc.frontend }
  frontend_port    = var.container_services[local.frontend_service].port

  # docker-compose.yml de la capa App: imagenes de ECR y conexion a la EC2 MySQL
  compose_file = templatefile("${path.root}/userdata/docker-compose.aws.yml.tftpl", {
    project_name     = var.project_name
    registry_url     = module.ecr[local.frontend_service].registry_url
    repo_prefix      = var.project_name
    docker_network   = "${var.project_name}-net"
    frontend_service = local.frontend_service
    frontend_port    = local.frontend_port
    backend_services = local.backend_services
    db_host          = module.database.db_address
    db_port          = module.database.db_port
    db_name          = var.db_config.db_name
    db_user          = var.db_config.username
    db_password      = var.db_config.password
  })

  # User data de las EC2 App: instala Docker y Compose, y levanta los 5 contenedores
  app_user_data = templatefile("${path.root}/userdata/freshbox-app.sh.tftpl", {
    aws_region   = var.aws_region
    registry_url = module.ecr[local.frontend_service].registry_url
    compose_file = local.compose_file
  })
}

# -----------------------------------------------------------------------------
# Red: VPC /22, 6 subredes /26 (publica, App y Data en 2 AZ), IGW, NAT GW y rutas
# -----------------------------------------------------------------------------
module "network" {
  source         = "./modules/network"
  project_name   = local.name_prefix
  vpc_cidr       = var.vpc_cidr
  subnet_newbits = var.subnet_newbits
  subnets_config = var.subnets_config
}

# -----------------------------------------------------------------------------
# Security Groups: SG-ALB (80/443 desde Internet) -> SG-APP (80/443 desde SG-ALB) -> SG-DATA (3306 desde SG-APP)
# -----------------------------------------------------------------------------
module "security" {
  source       = "./modules/security"
  project_name = local.name_prefix
  vpc_id       = module.network.vpc_id
  app_ingress_rules = [
    { from_port = 80, to_port = 80 },
    { from_port = 443, to_port = 443 },
  ]
}

# -----------------------------------------------------------------------------
# Amazon ECR: un repositorio por contenedor (freshbox-frontend, freshbox-get-products, ...)
# -----------------------------------------------------------------------------
module "ecr" {
  source   = "./modules/ecr"
  for_each = var.container_services

  project_name    = local.name_prefix                 # tag Project
  repository_name = "${var.project_name}-${each.key}" # sin prefijo: coincide con ecr-push.sh
}

# -----------------------------------------------------------------------------
# AMI: Amazon Linux 2023 ARM64 (Graviton)
# -----------------------------------------------------------------------------
module "ami" {
  source     = "./modules/ami"
  ami_config = var.ami_config
}

# -----------------------------------------------------------------------------
# Capa Data: EC2 MySQL en la subred privada Data de us-east-1a (EBS cifrado)
# -----------------------------------------------------------------------------
module "database" {
  source                    = "./modules/database"
  project_name              = local.name_prefix
  db_config                 = var.db_config
  subnet_id                 = module.network.db_private_subnet_ids[local.data_subnet_keys[0]]
  security_group_id         = module.security.db_sg_id
  ami_id                    = module.ami.ami_id
  instance_type             = var.instance_type
  iam_instance_profile_name = var.ec2_instance_profile_name
  user_data_template_path   = "${path.root}/userdata/freshbox-mysql.sh.tftpl"
  init_sql_path             = "${path.root}/../desarrolloappEP1/init.sql"

  # Espera a la red completa (NAT Gateway y rutas): el user data y el agente SSM
  # necesitan salida a Internet desde el primer arranque
  depends_on = [module.network]
}

# -----------------------------------------------------------------------------
# Capa App: plantilla de lanzamiento (EBS cifrado, LabInstanceProfile, user data de despliegue)
# -----------------------------------------------------------------------------
module "launch_template" {
  source                    = "./modules/launch_template"
  project_name              = local.name_prefix
  ami_id                    = module.ami.ami_id
  instance_type             = var.instance_type
  key_name                  = null
  security_group_ids        = [module.security.ec2_sg_id]
  iam_instance_profile_name = var.ec2_instance_profile_name
  root_device_name          = module.ami.root_device_name
  root_volume_size          = var.root_volume_size
  root_volume_encrypted     = true
  user_data                 = local.app_user_data

  # AWS Backup respalda solo la EC2 MySQL (Backup=daily); las EC2 App las gestiona el ASG
  tags = merge(local.common_tags, { Backup = "none" })
}

# -----------------------------------------------------------------------------
# Capa Web: Application Load Balancer en las subredes publicas, listener HTTP:80 -> Target Group
# -----------------------------------------------------------------------------
module "alb" {
  source             = "./modules/alb"
  project_name       = local.name_prefix
  vpc_id             = module.network.vpc_id
  subnet_ids         = values(module.network.public_subnet_ids)
  security_group_ids = [module.security.alb_sg_id]
  alb_config         = var.alb_config

  listeners = {
    http = { port = local.frontend_port, protocol = "HTTP", health_check_path = "/" }
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group Multi-AZ (min 2 / max 4) con escalado automatico por CPU
# -----------------------------------------------------------------------------
resource "aws_autoscaling_group" "app" {
  name                      = "${local.name_prefix}-app-asg"
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_min_size
  max_size                  = var.asg_max_size
  vpc_zone_identifier       = [for key in local.app_subnet_keys : module.network.app_private_subnet_ids[key]]
  target_group_arns         = values(module.alb.target_group_arns)
  health_check_type         = "ELB"
  health_check_grace_period = 600

  launch_template {
    id      = module.launch_template.launch_template_id
    version = module.launch_template.launch_template_latest_version
  }

  # El ASG no recibe default_tags: sus tags se declaran aqui (las instancias los toman de la plantilla)
  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "${local.name_prefix}-app-asg" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  lifecycle {
    # La capacidad deseada la ajusta la politica de escalado; Terraform no la revierte
    ignore_changes = [desired_capacity]
  }

  # Las instancias se lanzan cuando ya existen el NAT Gateway y las rutas privadas
  depends_on = [module.network]
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}

# -----------------------------------------------------------------------------
# AWS Backup: plan diario (retencion 7 dias) para la EC2 MySQL, restaurable en us-east-1b
# -----------------------------------------------------------------------------
module "backup" {
  source                   = "./modules/backup"
  project_name             = local.name_prefix
  aws_region               = var.aws_region
  enable_backup_selections = true

  depends_on = [module.database]
}
