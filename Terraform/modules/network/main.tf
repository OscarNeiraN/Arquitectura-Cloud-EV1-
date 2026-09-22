locals {
  public_subnets  = { for k, v in var.subnets_config : k => v if v.public }
  private_subnets = { for k, v in var.subnets_config : k => v if !v.public }

  app_private_subnets = {
    for k, v in local.private_subnets : k => v
    if try(v.tier, "app") == "app"
  }

  db_private_subnets = {
    for k, v in local.private_subnets : k => v
    if try(v.tier, "app") == "db"
  }

  # Un unico NAT Gateway (en la primera subred publica), igual al anexo ("NAT Gateway: In 1 AZ").
  # Lo comparten las subredes privadas APP y DATA de ambas AZ.
  nat_gateway_subnet_key = length(local.public_subnets) > 0 ? sort(keys(local.public_subnets))[0] : null
}

resource "aws_vpc" "main" {
  count                = var.enable_network ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name      = var.project_name
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "public" {
  for_each                = var.enable_network ? local.public_subnets : {}
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(aws_vpc.main[0].cidr_block, var.subnet_newbits, each.value.net_num)
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name      = each.key
    Project   = var.project_name
    Tier      = "public"
    ManagedBy = "Terraform"
  }
}

resource "aws_subnet" "private" {
  for_each                = var.enable_network ? local.private_subnets : {}
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(aws_vpc.main[0].cidr_block, var.subnet_newbits, each.value.net_num)
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  tags = {
    Name      = each.key
    Project   = var.project_name
    Tier      = try(each.value.tier, "app")
    ManagedBy = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  count  = var.enable_network ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name      = "${var.project_name}-igw"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_eip" "nat" {
  count  = var.enable_network && var.enable_nat_gateway && local.nat_gateway_subnet_key != null ? 1 : 0
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-nat-eip"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_network && var.enable_nat_gateway && local.nat_gateway_subnet_key != null ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[local.nat_gateway_subnet_key].id

  tags = {
    Name      = "${var.project_name}-nat"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  count  = var.enable_network ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name      = "${var.project_name}-public-rt"
    Project   = var.project_name
    Tier      = "public"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "app_private" {
  for_each = var.enable_network ? local.app_private_subnets : {}
  vpc_id   = aws_vpc.main[0].id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name      = "${each.key}-rt"
    Project   = var.project_name
    Tier      = "app"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "db_private" {
  count  = var.enable_network && length(local.db_private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name      = "${var.project_name}-private-db-rt"
    Project   = var.project_name
    Tier      = "db"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "app_private" {
  for_each       = { for k, v in aws_subnet.private : k => v if contains(keys(local.app_private_subnets), k) }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app_private[each.key].id
}

resource "aws_route_table_association" "db_private" {
  for_each       = { for k, v in aws_subnet.private : k => v if contains(keys(local.db_private_subnets), k) }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db_private[0].id
}
