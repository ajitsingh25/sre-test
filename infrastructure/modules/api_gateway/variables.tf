variable "post_task_lambda_arn" {
  description = "ARN of the post-task Lambda function"
  type        = string
}

variable "get_task_lambda_arn" {
  description = "ARN of the get-tasks Lambda function"
  type        = string
}

variable "post_task_lambda_name" {
  description = "Name of the post-task Lambda function"
  type        = string
}

variable "get_task_lambda_name" {
  description = "Name of the get-tasks Lambda function"
  type        = string
}
