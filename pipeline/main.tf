module "codebuild" {
  source         = "./modules/aws-build"
  codebuild_name = "sre"
  s3_tf_id       = "env-frontend-bucket-v1wryct6"
  git_repo       = "https://github.com/ajitsingh25/sre-test"
  git_user       = "ajitsingh25"
  git_branch     = "main"
}