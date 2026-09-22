data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  normalized_project_name = trim(replace(lower(var.project_name), "/[^a-z0-9-]/", "-"), "-")
  vault_name              = "${local.normalized_project_name}-backup-vault"
  plan_name               = "${local.normalized_project_name}-backup-plan"
  backup_rule_name        = "${local.normalized_project_name}-daily-backup"

  default_backup_role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  backup_role_arn         = trimspace(var.backup_service_role_arn) != "" ? trimspace(var.backup_service_role_arn) : local.default_backup_role_arn

  ec2_instance_arn_pattern = "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
}

resource "aws_backup_vault" "this" {
  count = var.enable_backup ? 1 : 0

  name = local.vault_name

  tags = {
    Name      = local.vault_name
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_backup_plan" "this" {
  count = var.enable_backup ? 1 : 0

  name = local.plan_name

  rule {
    rule_name         = local.backup_rule_name
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = var.backup_schedule_expression
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }

  tags = {
    Name      = local.plan_name
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_backup_selection" "ec2" {
  count = var.enable_backup && var.enable_backup_selections && var.enable_ec2_backup_selection ? 1 : 0

  name         = "${local.normalized_project_name}-ec2-selection"
  iam_role_arn = local.backup_role_arn
  plan_id      = aws_backup_plan.this[0].id
  resources    = [local.ec2_instance_arn_pattern]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.ec2_selection_tag_key
    value = var.ec2_selection_tag_value
  }
}
