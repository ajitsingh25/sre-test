# ✅ Create API Gateway HTTP API
resource "aws_apigatewayv2_api" "tasks_api" {
  name          = "tasks-api"
  protocol_type = "HTTP"
  description   = "API Gateway for serverless tasks management"

  cors_configuration {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_headers     = ["content-type"]
    allow_credentials = false
    max_age           = 30
  }
}

# ✅ Integration for POST /tasks
resource "aws_apigatewayv2_integration" "post_task_integration" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_uri        = var.post_task_lambda_arn
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
}

# ✅ Integration for GET /tasks
resource "aws_apigatewayv2_integration" "get_task_integration" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_uri        = var.get_task_lambda_arn
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
}

# ✅ Define API Gateway Route for POST /tasks
resource "aws_apigatewayv2_route" "post_task_route" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "POST /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.post_task_integration.id}"
}

# ✅ Define API Gateway Route for GET /tasks
resource "aws_apigatewayv2_route" "get_task_route" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "GET /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.get_task_integration.id}"
}

# ✅ Allow API Gateway to invoke Lambda functions
resource "aws_lambda_permission" "apigateway_post_permission" {
  action        = "lambda:InvokeFunction"
  function_name = var.post_task_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigateway_get_permission" {
  action        = "lambda:InvokeFunction"
  function_name = var.get_task_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.tasks_api.execution_arn}/*/*"
}

# ✅ Define API Gateway Route for OPTIONS /tasks (CORS)
resource "aws_apigatewayv2_route" "options_tasks" {
  api_id    = aws_apigatewayv2_api.tasks_api.id
  route_key = "OPTIONS /tasks"
  target    = "integrations/${aws_apigatewayv2_integration.options_tasks.id}"
}

# ✅ Integration for OPTIONS /tasks using HTTP_PROXY
resource "aws_apigatewayv2_integration" "options_tasks" {
  api_id                 = aws_apigatewayv2_api.tasks_api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "OPTIONS"
  integration_uri        = "https://httpbin.org/anything" # ✅ Responds with default headers
  payload_format_version = "1.0"
}

# ✅ Create CloudWatch Log Group for API Gateway Logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/tasks-api"
  retention_in_days = 30 # ✅ Retain logs for 30 days

  tags = {
    Name = "api-gateway-logs"
  }
}

# ✅ Enable CloudWatch Logging for API Gateway
resource "aws_apigatewayv2_stage" "tasks_api_stage" {
  api_id      = aws_apigatewayv2_api.tasks_api.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId        = "$context.requestId",
      requestTime      = "$context.requestTime",
      httpMethod       = "$context.httpMethod",
      resourcePath     = "$context.resourcePath",
      status           = "$context.status",
      responseLength   = "$context.responseLength",
      integrationError = "$context.integration.error"
    })
  }
}
