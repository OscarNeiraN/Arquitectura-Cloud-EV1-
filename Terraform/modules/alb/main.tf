resource "aws_lb" "app" {
  count                      = var.enable_alb ? 1 : 0
  name                       = var.alb_config.name
  load_balancer_type         = "application"
  internal                   = var.alb_config.internal
  security_groups            = var.security_group_ids
  subnets                    = var.subnet_ids
  enable_deletion_protection = false

  tags = {
    Name      = var.alb_config.name
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_lb_target_group" "app" {
  for_each = var.enable_alb ? var.listeners : {}

  name     = "${var.project_name}-tg-${each.key}"
  port     = each.value.port
  protocol = try(each.value.protocol, "HTTP")
  vpc_id   = var.vpc_id

  health_check {
    path                = try(each.value.health_check_path, "/")
    protocol            = try(each.value.protocol, "HTTP")
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name      = "${var.project_name}-tg-${each.key}"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_lb_listener" "app" {
  for_each = var.enable_alb ? var.listeners : {}

  load_balancer_arn = aws_lb.app[0].arn
  port              = each.value.port
  protocol          = try(each.value.protocol, "HTTP")

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[each.key].arn
  }
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = var.enable_alb ? {
    for pair in setproduct(keys(var.listeners), keys(var.target_instance_ids)) :
    "${pair[0]}-${pair[1]}" => { listener_key = pair[0], instance_key = pair[1] }
  } : {}

  target_group_arn = aws_lb_target_group.app[each.value.listener_key].arn
  target_id        = var.target_instance_ids[each.value.instance_key]
  port             = var.listeners[each.value.listener_key].port
}
