output "ami_id" {
  value = data.aws_ami.selected.id
}

output "root_device_name" {
  value = data.aws_ami.selected.root_device_name
}
