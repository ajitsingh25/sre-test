# ✅ Create Kinesis Data Stream
resource "aws_kinesis_stream" "kinesis_stream" {
  name        = "my_kinesis"
  shard_count = 1

  retention_period = 24 # Logs retention in hours

  tags = {
    Name = "KinesisToCloudWatch"
  }
}

# ✅ IAM Role for CloudWatch to Assume
resource "aws_iam_role" "cloudwatch_to_kinesis_role" {
  name = "CloudWatchToKinesisRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ✅ IAM Policy for CloudWatch to Send Logs to Kinesis
resource "aws_iam_policy" "cloudwatch_to_kinesis_policy" {
  name        = "CloudWatchToKinesisPolicy"
  description = "Allows CloudWatch to put logs into Kinesis"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary"
        ],
        Resource = aws_kinesis_stream.kinesis_stream.arn
      }
    ]
  })
}

# ✅ Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.cloudwatch_to_kinesis_role.name
  policy_arn = aws_iam_policy.cloudwatch_to_kinesis_policy.arn
}

# ✅ Send API Gateway Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "api_gateway_to_splunk" {
  name            = "kinesis-api-gateway-to-splunk"
  log_group_name  = var.api_gateway_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.kinesis_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis_role.arn
}

# ✅ Send Lambda Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "get_lambda_to_splunk" {
  name            = "kinesis-lambda-to-splunk"
  log_group_name  = var.get_task_lambda_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.kinesis_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis_role.arn
}

# ✅ Send Lambda Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "post_lambda_to_splunk" {
  name            = "kinesis-lambda-to-splunk"
  log_group_name  = var.post_task_lambda_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.kinesis_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis_role.arn
}

# ✅ Send RDS Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "rds_to_splunk" {
  name            = "kinesis-rds-to-splunk"
  log_group_name  = var.rds_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.kinesis_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis_role.arn
}

resource "aws_cloudwatch_log_subscription_filter" "rdsproxy_to_splunk" {
  name            = "kinesis-rdsproxy-to-splunk"
  log_group_name  = var.rdsproxy_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.kinesis_stream.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis_role.arn
}
