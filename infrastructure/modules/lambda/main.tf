# ✅ Ensure psycopg2_layer.zip is rebuilt only if `requirements.txt` changes
resource "null_resource" "build_psycopg2_layer" {
  triggers = {
    file_hash = filemd5("${path.root}/../lambda_functions/requirements.txt") # ✅ Track changes in requirements.txt
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.root}/../lambda_functions/psycopg2_layer
      mkdir -p ${path.root}/../lambda_functions/psycopg2_layer/python  # ✅ Correct Layer Structure
      pip install --platform manylinux2014_x86_64 --target=${path.root}/../lambda_functions/psycopg2_layer/python --implementation cp --python-version 3.9 --only-binary=:all: psycopg2-binary sentry-sdk
    #   pip install --platform manylinux2014_x86_64 --target=${path.root}/../lambda_functions/psycopg2_layer/python --implementation cp --python-version 3.9 --only-binary=:all: -r ${path.root}/../lambda_functions/requirements.txt
      cd ${path.root}/../lambda_functions/psycopg2_layer/
      zip -r psycopg2_layer.zip python
    EOT
  }
}


# ✅ AWS Lambda Layer for Dependencies
resource "aws_lambda_layer_version" "psycopg2_layer" {
  filename            = "${path.root}/../lambda_functions/psycopg2_layer/psycopg2_layer.zip"
  layer_name          = "psycopg2-layer"
  compatible_runtimes = ["python3.9"]
  #   depends_on = [null_resource.build_psycopg2_layer]  # ✅ Ensure layer is built before applying
  lifecycle {
    replace_triggered_by = [null_resource.build_psycopg2_layer]
  }
}

# ✅ Ensure post_task.zip is always updated
resource "null_resource" "build_post_task_zip" {
  triggers = {
    file_hash = filemd5("${path.root}/../lambda_functions/post_task.py") # ✅ Track changes based on file hash
  }

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.root}/../lambda_functions
      rm -f post_task.zip
      zip -r post_task.zip post_task.py
    EOT
  }
}

# ✅ Ensure get_tasks.zip is always updated
resource "null_resource" "build_get_tasks_zip" {
  triggers = {
    file_hash = filemd5("${path.root}/../lambda_functions/get_tasks.py") # ✅ Track changes based on file hash
  }

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.root}/../lambda_functions
      rm -f get_tasks.zip
      zip -r get_tasks.zip get_tasks.py
    EOT
  }
}

# ✅ AWS Lambda Function for POST /tasks
resource "aws_lambda_function" "post_task" {
  function_name = "post-task"
  runtime       = "python3.9"
  handler       = "post_task.lambda_handler"
  memory_size   = 512
  timeout       = 45
  role          = var.lambda_execution_role_arn                    # ✅ Use IAM role from IAM module
  filename      = "${path.root}/../lambda_functions/post_task.zip" # ✅ Use dynamically created ZIP

  layers = [aws_lambda_layer_version.psycopg2_layer.arn]

  vpc_config {
    security_group_ids = [var.lambda_sg_id]
    subnet_ids         = var.subnet_ids # ✅ Attach correct private subnets
  }

  depends_on = [var.rds_secret_name] # ✅ Ensure RDS is deployed first

  lifecycle {
    replace_triggered_by = [null_resource.build_post_task_zip]
  }

  environment {
    variables = {
      DB_HOST        = var.rds_proxy_endpoint # ✅ Use RDS Proxy instead of RDS
      DB_NAME        = var.db_name
      DB_SECRET_NAME = var.rds_secret_name
      SENTRY_DSN     = var.sentry_dsn # ✅ Sentry DSN for error monitoring
      LOG_LEVEL      = var.log_level  # ✅ Allows changing logging levels dynamically
      #   REGION     = var.region
    }
  }
}

# ✅ AWS Lambda Function for GET /tasks
resource "aws_lambda_function" "get_tasks" {
  function_name = "get-tasks"
  runtime       = "python3.9"
  handler       = "get_tasks.lambda_handler"
  memory_size   = 512
  timeout       = 45
  role          = var.lambda_execution_role_arn                    # ✅ Use IAM role from IAM module
  filename      = "${path.root}/../lambda_functions/get_tasks.zip" # ✅ Use dynamically created ZIP

  layers = [aws_lambda_layer_version.psycopg2_layer.arn]

  vpc_config {
    security_group_ids = [var.lambda_sg_id]
    subnet_ids         = var.subnet_ids # ✅ Attach correct private subnets
  }

  depends_on = [var.rds_secret_name] # ✅ Ensure RDS is deployed first

  lifecycle {
    replace_triggered_by = [null_resource.build_get_tasks_zip]
  }

  environment {
    variables = {
      DB_HOST        = var.rds_proxy_endpoint # ✅ Use RDS Proxy instead of RDS
      DB_NAME        = var.db_name
      DB_SECRET_NAME = var.rds_secret_name
      SENTRY_DSN     = var.sentry_dsn # ✅ Sentry DSN for error monitoring
      LOG_LEVEL      = var.log_level  # ✅ Allows changing logging levels dynamically
      #   REGION     = var.region
    }
  }
}
