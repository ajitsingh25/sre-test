# ✅ IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ IAM Policy for Lambda Execution
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy"
  description = "IAM policy for Lambda to access RDS, CloudWatch, and VPC Networking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.rds_secret_arn
      },
      {
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = var.rds_arn
      }
    ]
  })
}

# ✅ Attach IAM Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

# ✅ IAM Role for API Gateway Execution
resource "aws_iam_role" "apigateway_role" {
  name = "apigateway-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ IAM Policy for API Gateway to Invoke Lambda
resource "aws_iam_policy" "apigateway_policy" {
  name        = "apigateway-policy"
  description = "IAM policy for API Gateway to invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = var.lambda_arns
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway_policy_attach" {
  policy_arn = aws_iam_policy.apigateway_policy.arn
  role       = aws_iam_role.apigateway_role.name
}

# ✅ IAM Role for RDS Proxy Access
resource "aws_iam_role" "rds_proxy_role" {
  name = "rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ IAM Policy for Lambda to Connect to RDS Proxy
resource "aws_iam_policy" "rds_proxy_policy" {
  name        = "rds-proxy-policy"
  description = "Allows Lambda to connect to RDS Proxy and manage Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "SecretsManagerGeneralAccess",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:CreateSecret",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "SecretsManagerSpecificAccess",
        "Effect" : "Allow",
        "Action" : "secretsmanager:*",
        "Resource" : var.rds_secret_arn # ✅ Using the Terraform variable for RDS secret
      }
    ]
  })
}

# ✅ IAM Policy for Lambda to Connect to RDS Proxy
resource "aws_iam_policy" "lambda_rds_proxy_policy" {
  name        = "lambda-rds-proxy-policy"
  description = "Allows Lambda to connect to RDS Proxy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser/${var.rds_proxy_arn}/${var.db_user}"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.rds_secret_arn
      }
    ]
  })
}

# ✅ Attach Policy to RDS Proxy role
resource "aws_iam_role_policy_attachment" "rds_proxy_attachment" {
  role       = aws_iam_role.rds_proxy_role.name
  policy_arn = aws_iam_policy.rds_proxy_policy.arn
}

# ✅ Attach Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_rds_proxy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_rds_proxy_policy.arn
}

# ✅ IAM Policy for Lambda to Read Secrets Manager
resource "aws_iam_policy" "lambda_secrets_manager_policy" {
  name        = "lambda-secrets-manager-policy"
  description = "Allows Lambda to retrieve secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = var.rds_secret_arn # ✅ Ensure correct reference
    }]
  })
}

# ✅ Attach Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_secrets_manager_policy.arn
}

# ✅ IAM Role for API Gateway Logging
resource "aws_iam_role" "apigateway_logging_role" {
  name = "apigateway-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ IAM Policy to Allow API Gateway to Write Logs
resource "aws_iam_policy" "apigateway_logging_policy" {
  name        = "apigateway-logging-policy"
  description = "Allows API Gateway to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# ✅ Attach Policy to API Gateway Logging Role
resource "aws_iam_role_policy_attachment" "apigateway_logging_role_attachment" {
  role       = aws_iam_role.apigateway_logging_role.name
  policy_arn = aws_iam_policy.apigateway_logging_policy.arn
}


# ✅ 1. Create IAM Policy for Splunk Kinesis Read Access
resource "aws_iam_policy" "splunk_kinesis_policy" {
  name        = "SplunkKinesisReadOnlyPolicy"
  description = "Policy that allows Splunk to read from Kinesis streams"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

# ✅ 2. Create IAM Role for Splunk Kinesis
resource "aws_iam_role" "splunk_kinesis_role" {
  name = "SplunkKinesisRole"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::600627342239:user/splunkaccess"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

# ✅ 3. Attach Policy to IAM Role
resource "aws_iam_role_policy_attachment" "splunk_kinesis_attach" {
  policy_arn = aws_iam_policy.splunk_kinesis_policy.arn
  role       = aws_iam_role.splunk_kinesis_role.name
}
