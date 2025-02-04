resource "aws_iam_role" "codebuild_role" {
  name = var.codebuild_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.codebuild_name}-Policy"
  description = "Policy for AWS CodeBuild to run Terraform"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_role_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# #### Code Build Project
resource "aws_codebuild_project" "terraform_build" {
  name          = "${var.codebuild_name}-project"
  description   = "CodeBuild for running Terraform"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type            = "GITHUB"
    location        = var.git_repo
    git_clone_depth = 1
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "TF_BUCKET"
      value = var.s3_tf_id
    }
  }
}

# ### Pipeline

resource "aws_codepipeline" "terraform_pipeline" {
  name     = "${var.codebuild_name}-pipeline"
  role_arn = aws_iam_role.codebuild_role.arn

  artifact_store {
    location = var.s3_tf_id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "CheckoutCode"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        Owner      = var.git_user
        Repo       = var.git_repo
        Branch     = var.git_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "TerraformDeploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.terraform_build.id
      }
    }
  }
}
