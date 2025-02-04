output "sns_topic_arn" {
  value       = aws_sns_topic.error_alerts.arn
  description = "SNS topic ARN for error alerts"
}

output "cloudwatch_dashboard_url" {
  value       = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.sre_dashboard.dashboard_name}"
  description = "URL of the CloudWatch dashboard"
}

output "get_task_lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda_logs_get.name
}

output "post_task_lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda_logs_post.name
}
