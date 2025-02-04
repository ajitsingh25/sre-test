variable "codebuild_name" {
  type = string
}

variable "s3_tf_id" {
  type = string
}

variable "git_repo" {
  type = string
}

variable "git_user" {
  type = string
}

variable "github_token" {
  description = "GitHub OAuth Token for CodePipeline"
  type        = string
}

variable "git_branch" {
  type = string
}
