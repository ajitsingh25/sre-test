variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "db_user" {
  description = "Database user that Lambda will connect to via RDS Proxy"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of the RDS secret stored in Secrets Manager"
  type        = string
}

variable "rds_arn" {
  description = "ARN of the RDS instance"
  type        = string
}

variable "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
  type        = string
}

variable "lambda_execution_role_arn" {
  description = "IAM Role ARN for Lambda Execution"
  type        = string
}

variable "lambda_arns" {
  description = "List of Lambda function ARNs"
  type        = list(string)
}
