locals {
  user_data_template_path = coalesce(var.user_data_template_path, "${path.root}/userdata/escolaronline-mysql.sh.tftpl")
  init_sql_path           = coalesce(var.init_sql_path, "${path.root}/escolaronline-app/init.sql")

  user_data = var.create_db ? templatefile(local.user_data_template_path, {
    db_name     = try(var.db_config.db_name, "")
    db_user     = var.db_config.username
    db_password = var.db_config.password
    init_sql    = file(local.init_sql_path)
  }) : ""
}

resource "aws_instance" "mysql" {
  count = var.create_db ? 1 : 0

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile_name
  user_data                   = local.user_data

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name      = lower("${var.project_name}-mysql")
    Project   = var.project_name
    project   = var.project_name
    Backup    = "daily"
    ManagedBy = "Terraform"
  }
}
