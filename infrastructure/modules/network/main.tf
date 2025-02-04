# ✅ Fetch Default VPC
data "aws_vpc" "default" {
  default = true
}

# ✅ Fetch Default Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ✅ Fetch Available AZs
data "aws_availability_zones" "available" {}

# ✅ Create a Public Subnet for NAT Gateway
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.128.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "default-vpc-public-subnet"
  }
}

# ✅ Create Private Subnet in First AZ (eu-central-1a)
resource "aws_subnet" "rds_private_subnet_az1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.64.0/20" # ✅ Updated to an available CIDR
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rds-private-subnet-az1"
  }
}

# ✅ Create Private Subnet in Second AZ (eu-central-1b)
resource "aws_subnet" "rds_private_subnet_az2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.112.0/20" # ✅ Updated to an available CIDR
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "rds-private-subnet-az2"
  }
}

# ✅ Create Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-security-group"
  description = "Allow Lambda to connect to RDS"
  vpc_id      = data.aws_vpc.default.id
}

# ✅ Create Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound access for RDS from Lambda"
  vpc_id      = data.aws_vpc.default.id
}

# ✅ Create Security Group for RDS Proxy
resource "aws_security_group" "rds_proxy_sg" {
  name        = "rds-proxy-sg"
  description = "Allow inbound access for RDS Proxy to RDS"
  vpc_id      = data.aws_vpc.default.id
}

# # ✅ Create Security Group for RDS Proxy
# resource "aws_security_group" "vpc_endpoints_sg" {
#   name        = "vpc-endpoints-sg"
#   description = "Security Group for Kinesis & STS VPC Endpoints"
#   vpc_id      = data.aws_vpc.default.id
# }

# # ✅ Allow RDS to Access RDS Proxy (Ingress Rule)
# resource "aws_security_group_rule" "vpc_endpoints_sg_ingress" {
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.vpc_endpoints_sg.id
#   cidr_blocks       = [data.aws_vpc.default.cidr_block]
# }

# # ✅ Allow RDS Proxy to Reach External APIs
# resource "aws_security_group_rule" "vpc_endpoints_sg_egress" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1" # ✅ Allow all protocols (TCP, UDP, ICMP)
#   security_group_id = aws_security_group.vpc_endpoints_sg.id
#   cidr_blocks       = ["0.0.0.0/0"] # ✅ Allow traffic to all destinations
# }

# ✅ Allow RDS Proxy to Reach External APIs
resource "aws_security_group_rule" "rds_proxy_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # ✅ Allow all protocols (TCP, UDP, ICMP)
  security_group_id = aws_security_group.rds_proxy_sg.id
  cidr_blocks       = ["0.0.0.0/0"] # ✅ Allow traffic to all destinations
}

# ✅ Allow RDS to Access RDS Proxy (Ingress Rule)
resource "aws_security_group_rule" "rds_proxy_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_proxy_sg.id
  source_security_group_id = aws_security_group.rds_sg.id
}

# ✅ Allow Lambda to Reach External APIs
resource "aws_security_group_rule" "lambda_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"] # ✅ Allow outbound traffic to Sentry
}

# ✅ Allow API Gateway to Access Lambda (Ingress Rule)
resource "aws_security_group_rule" "lambda_ingress_apigw" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_sg.id
  source_security_group_id = aws_security_group.rds_sg.id
}

# ✅ Allow RDS to Accept Connections from Lambda (Ingress Rule)
resource "aws_security_group_rule" "rds_ingress_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}

# ✅ Allow RDS to Accept Connections from RDS Proxy (Ingress Rule)
resource "aws_security_group_rule" "rds_ingress_proxy" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.rds_proxy_sg.id
}

# ✅ Allow RDS to send outbound traffic to anywhere (All Traffic)
resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # ✅ Allow all protocols (TCP, UDP, ICMP)
  security_group_id = aws_security_group.rds_sg.id
  cidr_blocks       = ["0.0.0.0/0"] # ✅ Allow traffic to all destinations
}

# ✅ Create an Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# ✅ Create a NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id # ✅ Use a dedicated public subnet
}

# ✅ Create a Private Route Table for RDS
resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.default.id
}

# ✅ Route Internet Traffic from Private Subnet to NAT Gateway
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# ✅ Associate Both Private Subnets with Private Route Table
resource "aws_route_table_association" "private_association_az1" {
  subnet_id      = aws_subnet.rds_private_subnet_az1.id # ✅ Use AZ1 subnet
  route_table_id = aws_route_table.private_rt.id
}

# ✅ Associate Both Private Subnets with Private Route Table
resource "aws_route_table_association" "private_association_az2" {
  subnet_id      = aws_subnet.rds_private_subnet_az2.id # ✅ Use AZ2 subnet
  route_table_id = aws_route_table.private_rt.id
}

# ✅ Create a Security Group for the Secrets Manager VPC Endpoint
resource "aws_security_group" "secrets_manager_sg" {
  name        = "secrets-manager-sg"
  description = "Allow Lambda to access AWS Secrets Manager"
  vpc_id      = data.aws_vpc.default.id
}

# ✅ Allow inbound connections from Lambda to Secrets Manager
resource "aws_security_group_rule" "secrets_manager_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.secrets_manager_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id # ✅ Ensure Lambda can access Secrets Manager
}

# ✅ Allow outbound connections (Secrets Manager responses)
resource "aws_security_group_rule" "secrets_manager_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.secrets_manager_sg.id
  cidr_blocks       = ["0.0.0.0/0"] # ✅ Allow responses back to Lambda
}

# ✅ Allow Lambda to Reach AWS Secrets Manager
resource "aws_security_group_rule" "lambda_egress_secrets_manager" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_sg.id
  source_security_group_id = aws_security_group.secrets_manager_sg.id # ✅ Allow traffic to VPC Endpoint
}

# ✅ Create a VPC Endpoint for AWS Secrets Manager
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id             = data.aws_vpc.default.id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.rds_private_subnet_az1.id, aws_subnet.rds_private_subnet_az2.id] # ✅ Attach to private RDS subnets
  security_group_ids = [aws_security_group.secrets_manager_sg.id]                                   # ✅ Attach correct security group

  private_dns_enabled = true # ✅ Enable private DNS resolution for Secrets Manager

  tags = {
    Name = "secrets-manager-vpc-endpoint"
  }
}

# ✅ Fetch the Default Network ACL for the VPC
resource "aws_network_acl" "default_nacl" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_network_acls" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "default"
    values = [true]
  }
}

# ✅ Allow All Outbound Traffic in Default NACL
resource "aws_default_network_acl" "default" {
  default_network_acl_id = data.aws_network_acls.default.ids[0]

  lifecycle {
    ignore_changes = [subnet_ids] # ✅ Prevent changes to subnet associations
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ############# SPLUNK VPC ENDPOINT
# resource "aws_vpc_endpoint" "kinesis_endpoint" {
#   vpc_id             = data.aws_vpc.default.id # ✅ Fetch VPC ID dynamically
#   service_name       = "com.amazonaws.${var.aws_region}.kinesis-stream"
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = [aws_subnet.rds_private_subnet_az1.id, aws_subnet.rds_private_subnet_az2.id]
#   security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

#   private_dns_enabled = true
#   tags = {
#     Name = "Kinesis-Stream-Private-Endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "sts_endpoint" {
#   vpc_id             = data.aws_vpc.default.id # ✅ Fetch VPC ID dynamically
#   service_name       = "com.amazonaws.${var.aws_region}.sts"
#   vpc_endpoint_type  = "Interface"
#   subnet_ids         = [aws_subnet.rds_private_subnet_az1.id, aws_subnet.rds_private_subnet_az2.id]
#   security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

#   private_dns_enabled = true
#   tags = {
#     Name = "STS-Private-Endpoint"
#   }
# }
