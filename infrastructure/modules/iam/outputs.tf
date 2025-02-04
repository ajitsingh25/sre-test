output "lambda_execution_role_arn" {
  value       = aws_iam_role.lambda_exec.arn
  description = "IAM Role ARN for Lambda Execution"
}

output "rds_proxy_role_arn" {
  value       = aws_iam_role.rds_proxy_role.arn
  description = "IAM Role ARN for RDS Proxy"
}
