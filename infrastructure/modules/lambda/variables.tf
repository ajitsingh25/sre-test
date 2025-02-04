variable "lambda_sg_id" {
  description = "Security Group ID for Lambda"
  type        = string
}

variable "rds_host" {
  description = "RDS instance endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "rds_secret_name" {
  description = "RDS credentials secret Name"
  type        = string
}

variable "lambda_execution_role_arn" {
  description = "IAM Role ARN for Lambda Execution"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnets for Lambda"
  type        = list(string)
}

variable "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint"
  type        = string
}

variable "sentry_dsn" {
  description = "Sentry DSN for error monitoring"
  type        = string
}

variable "log_level" {
  description = "Log level for debugging (e.g., INFO, DEBUG, ERROR)"
  type        = string
  default     = "logging.INFO"
}

# variable "region" {
#   type = string
# }
