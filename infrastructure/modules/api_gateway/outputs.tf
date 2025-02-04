output "api_execution_arn" {
  value       = aws_apigatewayv2_api.tasks_api.execution_arn
  description = "API Gateway Execution ARN"
}

output "api_endpoint" {
  value       = aws_apigatewayv2_api.tasks_api.api_endpoint
  description = "API Gateway Endpoint URL"
}

output "api_gateway_log_group_name" {
  value = aws_cloudwatch_log_group.api_gateway_logs.name
}
