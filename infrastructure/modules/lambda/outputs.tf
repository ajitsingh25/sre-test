output "post_task_arn" {
  value       = aws_lambda_function.post_task.arn
  description = "ARN of the post-task Lambda function"
}

output "get_task_arn" {
  value       = aws_lambda_function.get_tasks.arn
  description = "ARN of the get-tasks Lambda function"
}

output "post_task_name" {
  value       = aws_lambda_function.post_task.function_name
  description = "Name of the post-task Lambda function"
}

output "get_task_name" {
  value       = aws_lambda_function.get_tasks.function_name
  description = "Name of the get-tasks Lambda function"
}
