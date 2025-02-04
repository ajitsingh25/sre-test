module "s3-backend" {
  source           = "./modules/s3"
  bucket_name      = "ajitsre"
  enable_s3_config = false
}

# ✅ Retrieve AWS Account ID
data "aws_caller_identity" "current" {}

# ✅ Network Module
module "network" {
  source     = "./modules/network"
  aws_region = local.aws_region
}

# ✅ S3 Module
module "s3" {
  source                      = "./modules/s3"
  bucket_name                 = local.bucket_name
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
  api_gateway_url             = module.api_gateway.api_endpoint # ✅ Pass API Gateway URL
}

# ✅ CloudFront Module
module "cloudfront" {
  source                    = "./modules/cloudfront"
  s3_bucket_regional_domain = module.s3.s3_bucket_regional_domain
}

# ✅ RDS Module
module "rds" {
  source = "./modules/rds"

  db_identifier           = local.db_identifier
  db_name                 = local.db_name
  db_username             = local.db_username
  instance_class          = local.instance_class
  allocated_storage       = local.allocated_storage
  security_group_id       = module.network.rds_sg_id
  rds_subnet_ids          = module.network.rds_private_subnet_ids # ✅ Pass multiple subnets
  backup_retention_period = local.backup_retention_period
  deletion_protection     = local.deletion_protection
  skip_final_snapshot     = local.skip_final_snapshot
  rds_proxy_role_arn      = module.iam.rds_proxy_role_arn # ✅ Pass IAM Role ARN
  proxy_security_group_id = module.network.rds_proxy_sg_id
}

# ✅ API Gateway Module
module "api_gateway" {
  source                = "./modules/api_gateway"
  post_task_lambda_arn  = module.lambda.post_task_arn
  get_task_lambda_arn   = module.lambda.get_task_arn
  post_task_lambda_name = module.lambda.post_task_name
  get_task_lambda_name  = module.lambda.get_task_name
}

# ✅ Lambda Module
module "lambda" {
  source = "./modules/lambda"
  # region                    = local.aws_region
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn # ✅ Pass IAM role from IAM module
  lambda_sg_id              = module.network.lambda_sg_id
  subnet_ids                = module.network.rds_private_subnet_ids # ✅ Pass correct private subnets
  rds_proxy_endpoint        = module.rds.rds_proxy_endpoint         # ✅ Use RDS Proxy instead of RDS instance
  rds_host                  = module.rds.rds_proxy_endpoint         # ✅ Use RDS Proxy instead of RDS instance
  db_name                   = local.db_name
  db_username               = local.db_username
  rds_secret_name           = module.rds.db_secret_name
  sentry_dsn                = local.sentry_dsn
  log_level                 = local.log_level
}

# ✅ IAM Module
module "iam" {
  source                    = "./modules/iam"
  aws_region                = local.aws_region
  aws_account_id            = data.aws_caller_identity.current.account_id
  db_user                   = local.db_username
  rds_secret_arn            = module.rds.rds_secret_id # ✅ Pass correct RDS Secret ARN
  rds_arn                   = module.rds.rds_arn
  rds_proxy_arn             = module.rds.rds_proxy_arn
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn
  lambda_arns               = [module.lambda.post_task_arn, module.lambda.get_task_arn]
}

# ✅ Cloudwatch Module
module "cloudwatch" {
  source                = "./modules/cloudwatch"
  post_task_lambda_name = module.lambda.post_task_name
  get_task_lambda_name  = module.lambda.get_task_name
  api_gateway_id        = module.api_gateway.api_execution_arn
  lambda_execution_role = module.iam.lambda_execution_role_arn
  aws_region            = local.aws_region            # ✅ Add AWS Region for CloudWatch Metrics
  dashboard_name        = "LambdaMonitoringDashboard" # ✅ New: Dashboard Name
}

module "kinesis" {
  source                          = "./modules/kinesis"
  rds_log_group_name              = "/aws/rds/instance/${local.db_identifier}/postgresql"
  post_task_lambda_log_group_name = module.cloudwatch.post_task_lambda_log_group_name
  get_task_lambda_log_group_name  = module.cloudwatch.get_task_lambda_log_group_name
  api_gateway_log_group_name      = module.api_gateway.api_gateway_log_group_name
  rdsproxy_log_group_name         = "/aws/rds/proxy/${module.rds.rds_proxy_name}"
}

# module "codebuild" {
#   source         = "./modules/aws-build"
#   codebuild_name = "sre"
#   s3_tf_id       = module.s3.s3_bucket_id
#   git_repo       = "https://github.com/ajitsingh25/sre-test"
#   git_user       = "ajitsingh25"
#   git_branch     = "main"
# }