output "db_instance_identifier" {
  value       = module.rds.db_instance_identifier
  description = "RDS instance identifier"
}

# ✅ Fetch RDS Instance Information for Outputs
# data "aws_db_instance" "rds" {
#   db_instance_identifier = module.rds.db_instance_identifier
#   depends_on = [module.rds]  # Ensure the module is created before
# }

# ✅ Output RDS Hostname (Without Port)
output "rds_db_url" {
  value       = data.aws_db_instance.rds.address
  description = "RDS Database URL without port"
  depends_on  = [module.rds] # Ensure the module is created before
}

output "rds_secret_id" {
  value       = data.aws_db_instance.rds.master_user_secret[0].secret_arn
  description = "RDS Database secret_id"
  depends_on  = [module.rds] # Ensure the module is created before
}

data "aws_secretsmanager_secret" "db_secret" {
  arn = data.aws_db_instance.rds.master_user_secret[0].secret_arn # ✅ Use the existing secret ARN
}

output "db_secret_name" {
  value       = data.aws_secretsmanager_secret.db_secret.name
  description = "The name of the Secrets Manager secret"
}

output "db_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "RDS instance endpoint"
}

output "db_instance_arn" {
  value       = module.rds.db_instance_arn # ✅ Ensure this is correctly referenced
  description = "ARN of the RDS instance"
}

output "rds_proxy_endpoint" {
  value       = aws_db_proxy.rds_proxy.endpoint
  description = "Endpoint of the RDS Proxy"
}

output "rds_instance_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "RDS instance endpoint (if needed as a fallback)"
}

output "rds_proxy_arn" {
  value       = aws_db_proxy.rds_proxy.arn
  description = "ARN of the RDS Proxy"
}

output "rds_proxy_name" {
  value       = aws_db_proxy.rds_proxy.name
  description = "ARN of the RDS Proxy"
}

output "rds_arn" {
  value       = module.rds.db_instance_arn # ✅ FIXED: Correct reference
  description = "ARN of the RDS Instance"
}

output "rds_log_group_name" {
  value = module.rds.db_instance_cloudwatch_log_groups
}
