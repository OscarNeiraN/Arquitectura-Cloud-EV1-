resource "aws_launch_template" "this" {
  name_prefix = "${var.project_name}-${var.name_prefix}-"

  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name == null ? [] : [var.iam_instance_profile_name]

    content {
      name = iam_instance_profile.value
    }
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    device_index                = 0
    security_groups             = var.security_group_ids
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.root_volume_encrypted
      delete_on_termination = true
    }
  }

  # User data script.
  user_data = var.user_data_file != null ? base64encode(file(var.user_data_file)) : (var.user_data != null && var.user_data != "" ? base64encode(var.user_data) : null)

  monitoring {
    enabled = var.monitoring
  }

  ebs_optimized = var.ebs_optimized

  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  tags = merge(
    {
      Name      = "${var.project_name}-launch-template"
      Project   = var.project_name
      project   = var.project_name
      Backup    = "daily"
      ManagedBy = "Terraform"
    },
    var.tags
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        Name      = "${var.project_name}-app-instance"
        Project   = var.project_name
        project   = var.project_name
        Backup    = "daily"
        ManagedBy = "Terraform"
      },
      var.tags
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      {
        Name      = "${var.project_name}-app-volume"
        Project   = var.project_name
        project   = var.project_name
        Backup    = "daily"
        ManagedBy = "Terraform"
      },
      var.tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}
