variable "post_task_lambda_name" {
  description = "Name of the post-task Lambda function"
  type        = string
}

variable "get_task_lambda_name" {
  description = "Name of the get-tasks Lambda function"
  type        = string
}

variable "api_gateway_id" {
  description = "ID of the API Gateway"
  type        = string
}

variable "lambda_execution_role" {
  description = "IAM Role for Lambda execution"
  type        = string
}

variable "aws_region" {
  description = "AWS Region where CloudWatch is deployed"
  type        = string
}

variable "dashboard_name" {
  description = "CloudWatch Dashboard Name"
  type        = string
}
