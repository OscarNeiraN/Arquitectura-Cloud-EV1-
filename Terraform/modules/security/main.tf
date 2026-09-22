resource "aws_security_group" "alb" {
  name        = lower("${var.project_name}-alb-sg")
  description = "Allow HTTP traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = lower("${var.project_name}-alb-sg")
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_security_group" "ec2" {
  name        = lower("${var.project_name}-ec2-sg")
  description = "EC2 app security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.app_ingress_rules

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = "tcp"
      security_groups = [aws_security_group.alb.id]
      self            = false
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = lower("${var.project_name}-ec2-sg")
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_security_group" "db" {
  name        = lower("${var.project_name}-db-sg")
  description = "Database security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    self            = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = lower("${var.project_name}-db-sg")
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
