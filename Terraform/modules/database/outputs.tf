output "db_address" {
  value = one(aws_instance.mysql[*].private_ip)
}

output "db_port" {
  value = 3306
}

output "db_identifier" {
  value = coalesce(try(one(aws_instance.mysql[*].id), null), "")
}

output "db_instance_id" {
  value = coalesce(try(one(aws_instance.mysql[*].id), null), "")
}

output "db_arn" {
  value = coalesce(try(one(aws_instance.mysql[*].arn), null), "")
}
