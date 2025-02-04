locals {
  env        = "env"
  aws_region = "us-west-2"

  # ✅ S3 Bucket Name
  bucket_name = "${local.env}-frontend-bucket"

  # ✅ RDS Database Configuration
  db_identifier = "${local.env}task-db"
  db_name       = "${local.env}task_db"
  db_username   = "${local.env}taskadmin"

  # ✅ Instance Class and Storage Configuration
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  # ✅ Cloudwatch Configuration
  cloudwatch_dashboard_name = "${local.env}-dashboard"
  #   rds_log_group_name = "/aws/rds/instance/${db_identifier}/postgresql"

  # ✅ Sentry Configuration
  sentry_dsn = "https://f5a40bb59937b735731b7c78fc85a6a5@o4508747773837312.ingest.de.sentry.io/4508747779145808"
  log_level  = "INFO"

  #   AWS CodeBUild
  codebuild_name = "TerraformCodeBuildRole"
}
