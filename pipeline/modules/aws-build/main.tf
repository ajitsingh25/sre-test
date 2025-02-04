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
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
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

    environment_variable {
      name  = "GIT_USER"
      value = var.git_user
    }

    environment_variable {
      name  = "GIT_REPO"
      value = var.git_repo
    }
  }
  
}

# ### Pipeline
data "aws_secretsmanager_secret" "git_secret" {
  name = "git-personal-token"
}

data "aws_secretsmanager_secret_version" "git_secret_value" {
  secret_id = data.aws_secretsmanager_secret.git_secret.id
}

####
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.codebuild_name}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${var.codebuild_name}-pipeline-policy"
  description = "IAM policy for CodePipeline to deploy Terraform"

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
        Resource = "arn:aws:s3:::${var.s3_tf_id}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource = aws_codebuild_project.terraform_build.arn
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = aws_iam_role.codebuild_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

######

resource "aws_codepipeline" "terraform_pipeline" {
  name     = "${var.codebuild_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn 

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
        OAuthToken = jsondecode(data.aws_secretsmanager_secret_version.git_secret_value.secret_string)["token"]
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
