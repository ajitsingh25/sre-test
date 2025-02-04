# ✅ Create RDS Subnet Group Covering Multiple AZs
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-private-subnet-group"
  subnet_ids = var.rds_subnet_ids # ✅ Use multiple private subnets

  tags = {
    Name = "RDS Private Subnet Group"
  }
}

# ✅ Create RDS PostgreSQL Database
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.5.0"

  identifier                  = var.db_identifier
  engine                      = "postgres"
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  publicly_accessible         = false
  vpc_security_group_ids      = [var.security_group_id]

  backup_retention_period         = var.backup_retention_period
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  performance_insights_enabled    = true
  family                          = "postgres16"
  db_subnet_group_name            = aws_db_subnet_group.rds_subnet_group.name
  enabled_cloudwatch_logs_exports = ["postgresql"]
}

# ✅ Fetch RDS Instance Information for Outputs
data "aws_db_instance" "rds" {
  db_instance_identifier = module.rds.db_instance_identifier
  depends_on             = [module.rds] # Ensure the module is created before
}

# ✅ Use IAM Role from IAM Module
resource "aws_db_proxy" "rds_proxy" {
  name                   = "rds-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = var.rds_proxy_role_arn # ✅ Use IAM Role from `iam` module
  vpc_subnet_ids         = var.rds_subnet_ids
  vpc_security_group_ids = [var.proxy_security_group_id]
  require_tls            = false

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = data.aws_db_instance.rds.master_user_secret[0].secret_arn
    iam_auth    = "DISABLED"
  }
}

# ✅ Create Proxy Target Group
resource "aws_db_proxy_target" "rds_proxy_target" {
  db_proxy_name          = aws_db_proxy.rds_proxy.name
  target_group_name      = "default"
  db_instance_identifier = module.rds.db_instance_identifier # ✅ FIXED: Corrected attribute name
}
