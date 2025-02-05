module "s3-backend" {
  source           = "../infrastructure/modules/s3"
  bucket_name      = "terraform-state"
  enable_s3_config = false
}

module "codebuild" {
  source         = "./modules/aws-build"
  codebuild_name = "sre"
  s3_tf_id       = "env-frontend-bucket-v1wryct6"
  git_repo       = "sre-test"
  git_user       = "ajitsingh25"
  git_branch     = "main"
}