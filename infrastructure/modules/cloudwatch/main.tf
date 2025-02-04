# ✅ CloudWatch Log Groups for Lambda Functions
resource "aws_cloudwatch_log_group" "lambda_logs_post" {
  name              = "/lambda/${var.post_task_lambda_name}"
  retention_in_days = 7

  depends_on = [var.lambda_execution_role] # ✅ Ensures Lambda role is created first
}

resource "aws_cloudwatch_log_group" "lambda_logs_get" {
  name              = "/lambda/${var.get_task_lambda_name}"
  retention_in_days = 7

  depends_on = [var.lambda_execution_role] # ✅ Ensures Lambda role is created first
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/api_gateway/tasks-api"
  retention_in_days = 7

  #   depends_on = [var.lambda_execution_role]  # ✅ Ensures Lambda role is created first
}

# ✅ SNS Topic for Alerting
resource "aws_sns_topic" "error_alerts" {
  name = "lambda-error-alerts"
}

# ✅ CloudWatch Alarms for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "lambda-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Triggers when Lambda errors exceed threshold"
  alarm_actions       = [aws_sns_topic.error_alerts.arn]

  depends_on = [aws_cloudwatch_log_group.lambda_logs_post, aws_cloudwatch_log_group.lambda_logs_get] # ✅ Ensure logs exist first
}

# ✅ CloudWatch Alarm for Lambda Execution Duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration_alarm" {
  alarm_name          = "lambda-duration-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "Lambda"
  period              = "60"
  statistic           = "Average"
  threshold           = "3000" # 3 seconds threshold
  alarm_description   = "Triggers when Lambda execution time exceeds threshold"
  alarm_actions       = [aws_sns_topic.error_alerts.arn]

  depends_on = [aws_cloudwatch_log_group.lambda_logs_post, aws_cloudwatch_log_group.lambda_logs_get] # ✅ Ensure logs exist first
}

# ✅ CloudWatch Dashboard for API & Lambda Monitoring
resource "aws_cloudwatch_dashboard" "sre_dashboard" {
  dashboard_name = "SRE-API-Metrics"

  dashboard_body = jsonencode({
    widgets = [
      # ✅ Lambda Metrics for Post Task
      {
        "type" : "metric",
        "properties" : {
          "region" : "eu-central-1",
          "title" : "Post Task Lambda Metrics",
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", var.post_task_lambda_name, { "stat" : "Sum" }],
            ["AWS/Lambda", "Errors", "FunctionName", var.post_task_lambda_name, { "stat" : "Sum" }],
            ["AWS/Lambda", "Duration", "FunctionName", var.post_task_lambda_name, { "stat" : "Average" }]
          ]
        }
      },

      # ✅ Lambda Metrics for Get Tasks
      {
        "type" : "metric",
        "properties" : {
          "region" : "eu-central-1",
          "title" : "Get Tasks Lambda Metrics",
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", var.get_task_lambda_name, { "stat" : "Sum" }],
            ["AWS/Lambda", "Errors", "FunctionName", var.get_task_lambda_name, { "stat" : "Sum" }],
            ["AWS/Lambda", "Duration", "FunctionName", var.get_task_lambda_name, { "stat" : "Average" }]
          ]
        }
      },

      # ✅ API Gateway Metrics
      {
        "type" : "metric",
        "properties" : {
          "region" : "eu-central-1",
          "title" : "API Gateway Metrics",
          "metrics" : [
            ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, { "stat" : "Sum" }],
            ["AWS/ApiGateway", "5XXError", "ApiId", var.api_gateway_id, { "stat" : "Sum" }]
          ]
        }
      }
    ]
  })

  depends_on = [aws_cloudwatch_metric_alarm.lambda_error_alarm, aws_cloudwatch_metric_alarm.lambda_duration_alarm] # ✅ Ensure alarms exist first
}

# ✅ CloudWatch Alarm for API Gateway 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_errors" {
  alarm_name          = "High-Error-Rate-API"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggers when API Gateway 5XX errors exceed 5 per minute"
  alarm_actions       = [aws_sns_topic.error_alerts.arn]
}
