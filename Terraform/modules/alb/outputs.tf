output "alb_dns_name" {
  value = try(aws_lb.app[0].dns_name, "")
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.app : k => v.arn }
}
