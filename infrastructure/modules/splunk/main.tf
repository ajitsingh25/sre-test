# ✅ Security Group for Splunk EC2 Instance
resource "aws_security_group" "splunk_sg" {
  name        = "splunk-security-group"
  description = "Allow inbound traffic to Splunk"
  vpc_id      = var.vpc_id

  # ✅ Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "splunk-security-group"
  }
}

# ✅ Allow HTTP access to Splunk Web UI
resource "aws_security_group_rule" "splunk_http" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  security_group_id = aws_security_group.splunk_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ✅ Allow HTTPS access to Splunk Web UI
resource "aws_security_group_rule" "splunk_https" {
  type              = "ingress"
  from_port         = 8088
  to_port           = 8088
  protocol          = "tcp"
  security_group_id = aws_security_group.splunk_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ✅ Security Group for SSM VPC Endpoints
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm-endpoint-sg"
  description = "Allow EC2 instances to connect to SSM"
  vpc_id      = var.vpc_id

  # ✅ Allow inbound traffic from EC2 instances to SSM
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.splunk_sg.id]
    # security_group_id = aws_security_group.splunk_sg.id  # ✅ Allow EC2 instances to access SSM
  }

  # ✅ Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ Create a VPC Endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

# ✅ Create a VPC Endpoint for EC2 Messages
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

# ✅ IAM Role for EC2 with Session Manager Access
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ Attach AWS Managed Policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ✅ Instance Profile for EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# ✅ Generate a Random Password for Splunk Admin
resource "random_password" "splunk_admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>:?"
}

# ✅ Store the Generated Password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "splunk_password" {
  name = var.splunk_secret_docker
}

resource "aws_secretsmanager_secret_version" "splunk_password_version" {
  secret_id     = aws_secretsmanager_secret.splunk_password.id
  secret_string = random_password.splunk_admin_password.result
}

# ✅ Define Local Variable for Password
locals {
  splunk_password = random_password.splunk_admin_password.result
}

# ✅ Fetch the latest Amazon Linux 2 AMI dynamically based on the region
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] # ✅ Fetch Amazon Linux 2 AMI
  }

  filter {
    name   = "owner-id"
    values = ["137112412989"] # ✅ Amazon's Official AWS AMI Account
  }
}

# ✅ EC2 Instance for Splunk in Private Subnet (No SSH, Only Session Manager)
resource "aws_instance" "splunk_server" {
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = var.instance_type
  subnet_id            = var.rds_private_subnet_az1 # ✅ Deploy in private subnet
  security_groups      = [aws_security_group.splunk_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name # ✅ Allow Session Manager access

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker aws-cli
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ec2-user

              # ✅ Run Splunk in Docker
              sudo docker run -d --restart unless-stopped -p 8000:8000 -p 8088:8088 -p 8089:8089 \
                  -e "SPLUNK_START_ARGS=--accept-license" \
                  -e "SPLUNK_PASSWORD=$splunk_password" \
                  --name splunk splunk/splunk:latest
              EOF

  root_block_device {
    volume_size = 50    # ✅ Increase root volume to 50GB
    volume_type = "gp3" # ✅ Use General Purpose SSD
  }

  tags = {
    Name = "Splunk-Server"
  }

  lifecycle {
    ignore_changes = [security_groups] # ✅ Prevent Terraform from replacing EC2 instance due to SG updates
  }
}

# ✅ Security Group for Classic Load Balancer
resource "aws_security_group" "splunk_lb_sg" {
  name        = "splunk-lb-sg"
  description = "Allow HTTP access to Splunk through Load Balancer"
  vpc_id      = var.vpc_id

  # ✅ Allow HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ✅ Allow HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ✅ Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ Fetch Available AZs
data "aws_availability_zones" "available" {}


# ✅ Generate a Self-Signed Certificate
resource "tls_private_key" "splunk_ssl_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "splunk_ssl_cert" {
  private_key_pem = tls_private_key.splunk_ssl_key.private_key_pem

  subject {
    common_name  = "splunk-classic-lb-1733595384.eu-central-1.elb.amazonaws.com" # ✅ Change to your domain or placeholder
    organization = "Splunk Inc"
  }

  validity_period_hours = 8760 # ✅ Valid for 1 year (365 days)
  is_ca_certificate     = false

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]

}

# ✅ Upload Certificate to AWS ACM
resource "aws_acm_certificate" "splunk_acm_cert" {
  private_key       = tls_private_key.splunk_ssl_key.private_key_pem
  certificate_body  = tls_self_signed_cert.splunk_ssl_cert.cert_pem
  certificate_chain = tls_self_signed_cert.splunk_ssl_cert.cert_pem
}


# ✅ Create a Classic Load Balancer for Splunk
resource "aws_elb" "splunk_lb" {
  name            = "splunk-classic-lb"
  security_groups = [aws_security_group.splunk_lb_sg.id]
  subnets         = [var.public_subnet_ids] # ✅ Deploy in public subnets

  listener {
    instance_port     = 8000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  # ✅ HTTPS Listener (Port 443) with Self-Signed Certificate
  listener {
    instance_port      = 8088
    instance_protocol  = "HTTPS"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate.splunk_acm_cert.arn
  }

  health_check {
    target              = "HTTPS:8088/services/collector/health/1.0"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [aws_instance.splunk_server.id] # ✅ Attach Splunk EC2 Instance

  tags = {
    Name = "splunk-classic-lb"
  }
}

# ✅ Allow CLB to access Splunk EC2
resource "aws_security_group_rule" "splunk_lb_to_ec2" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.splunk_sg.id
  source_security_group_id = aws_security_group.splunk_lb_sg.id
  depends_on               = [aws_security_group.splunk_sg]
}

# ✅ IAM Role for Kinesis Firehose to Write to Splunk & S3
resource "aws_iam_role" "kinesis_firehose" {
  name        = "kinesis-firehose-role"
  description = "IAM Role for Kinesis Firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ IAM Policy for Kinesis Firehose
resource "aws_iam_policy" "kinesis_firehose_policy" {
  name        = "kinesis-firehose-policy"
  description = "Allows Kinesis Firehose to send logs to Splunk and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "${var.bucket_arn}",
          "${var.bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecordBatch",
          "firehose:PutRecord"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.splunk_firehose.arn
      }
    ]
  })
}

# ✅ Attach Policy to Kinesis Firehose Role
resource "aws_iam_role_policy_attachment" "kinesis_firehose_attach" {
  role       = aws_iam_role.kinesis_firehose.name
  policy_arn = aws_iam_policy.kinesis_firehose_policy.arn
}

# ✅ Create CloudWatch Log Group for Kinesis Firehose
resource "aws_cloudwatch_log_group" "kinesis_logs" {
  name              = "/aws/kinesisfirehose/splunk"
  retention_in_days = 3
}

# ✅ Create CloudWatch Log Stream for Kinesis Firehose
resource "aws_cloudwatch_log_stream" "kinesis_logs" {
  name           = "firehose-logs"
  log_group_name = aws_cloudwatch_log_group.kinesis_logs.name
}

# ✅ Create Kinesis Firehose Delivery Stream for Splunk
resource "aws_kinesis_firehose_delivery_stream" "splunk_firehose" {
  name        = "splunk-firehose"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint               = "https://prd-p-gcxgi.splunkcloud.com/" # ✅ Use Splunk’s Public IP
    hec_token                  = var.splunk_hec_token                   # ✅ Securely pass HEC token
    hec_acknowledgment_timeout = 300
    retry_duration             = 300
    s3_backup_mode             = "FailedEventsOnly"
    hec_endpoint_type          = "Raw"

    s3_configuration {
      role_arn           = aws_iam_role.kinesis_firehose.arn
      prefix             = "kinesis-firehose/"
      bucket_arn         = var.bucket_arn
      buffering_size     = 5
      buffering_interval = 300
      compression_format = "GZIP"
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/splunk"
      log_stream_name = "firehose-logs"
    }
  }
}

# ✅ Fix IAM Role for CloudWatch to Firehose
resource "aws_iam_role" "cloudwatch_to_firehose_trust" {
  name        = "cloudwatch_to_firehose_trust_role"
  description = "Role for CloudWatch Log Group subscriptions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ✅ Add IAM Policy for CloudWatch to Firehose
resource "aws_iam_policy" "cloudwatch_to_firehose_policy" {
  name        = "cloudwatch-to-firehose-policy"
  description = "Allows CloudWatch to send logs to Firehose"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch",
          "logs:PutSubscriptionFilter",
          "iam:PassRole"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.splunk_firehose.arn
      }
    ]
  })
}

# ✅ Attach Policy to IAM Role
resource "aws_iam_role_policy_attachment" "cloudwatch_to_firehose_attach" {
  role       = aws_iam_role.cloudwatch_to_firehose_trust.name
  policy_arn = aws_iam_policy.cloudwatch_to_firehose_policy.arn
}

# ✅ Send API Gateway Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "api_gateway_to_splunk" {
  name            = "api-gateway-to-splunk"
  log_group_name  = var.api_gateway_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.splunk_firehose.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_trust.arn
  depends_on      = [aws_kinesis_firehose_delivery_stream.splunk_firehose]
}

# ✅ Send Lambda Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "get_lambda_to_splunk" {
  name            = "lambda-to-splunk"
  log_group_name  = var.get_task_lambda_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.splunk_firehose.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_trust.arn
  depends_on      = [aws_kinesis_firehose_delivery_stream.splunk_firehose]
}

# ✅ Send Lambda Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "post_lambda_to_splunk" {
  name            = "lambda-to-splunk"
  log_group_name  = var.post_task_lambda_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.splunk_firehose.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_trust.arn
  depends_on      = [aws_kinesis_firehose_delivery_stream.splunk_firehose]
}

# ✅ Send RDS Logs to Kinesis Firehose
resource "aws_cloudwatch_log_subscription_filter" "rds_to_splunk" {
  name            = "rds-to-splunk"
  log_group_name  = var.rds_log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.splunk_firehose.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose_trust.arn
  depends_on      = [aws_kinesis_firehose_delivery_stream.splunk_firehose]
}
