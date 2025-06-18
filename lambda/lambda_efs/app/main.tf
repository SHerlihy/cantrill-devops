terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "cantrill-general-admin"
  region  = "us-east-1"
}

variable "vpc_id" {
    type = string
}

variable "public_subnet" {
  type= string
}

variable "private_subnet" {
    type = string
}

resource "aws_security_group" "sg_for_lambda" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "efs_for_lambda" {}

# Mount target connects the file system to the subnet
resource "aws_efs_mount_target" "alpha" {
  file_system_id  = aws_efs_file_system.efs_for_lambda.id
  subnet_id       = var.private_subnet
  security_groups = [aws_security_group.sg_for_lambda.id]
}

# EFS access point used by lambda file system
resource "aws_efs_access_point" "access_point_for_lambda" {
  file_system_id = aws_efs_file_system.efs_for_lambda.id
  
  root_directory {
    path = "/cats"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }
}

data "archive_file" "deployment" {
  type        = "zip"
  source_file = "${path.module}/deployment.py"
  output_path = "${path.module}/deployment.zip"
  output_file_mode = "0666"
}

data "archive_file" "packages" {
  type        = "zip"
  source_dir = "${path.module}/layer_packages"
  output_path = "${path.module}/packages.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_layer_version" "packages" {
  filename = data.archive_file.packages.output_path
  layer_name = "packages"

  compatible_runtimes = ["python3.9"]
}

resource "aws_lambda_function" "app" {
  filename = data.archive_file.deployment.output_path
  handler = "deployment.lambda_handler"
  function_name = "app"
  runtime = "python3.9"
  architectures = ["x86_64"]

  role = aws_iam_role.lambda_exec.arn
  timeout = 60

  layers = [aws_lambda_layer_version.packages.arn]

  file_system_config {
    arn = aws_efs_access_point.access_point_for_lambda.arn
    local_mount_path = "/mnt/efs"
  }

  vpc_config {
    subnet_ids         = [var.private_subnet]
    security_group_ids = [aws_security_group.sg_for_lambda.id]
  }

  depends_on = [aws_efs_mount_target.alpha]
}

resource "aws_cloudwatch_log_group" "app" {
  name = "/aws/lambda/${aws_lambda_function.app.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_efs" {
    statement {
    effect = "Allow"
    actions = [
      "efs:*",
    ]

    resources = [
      "arn:aws:efs:::*",
    ]
  }
}

resource "aws_iam_policy" "lambda_efs" {
  name        = "lambda-efs"
  policy      = data.aws_iam_policy_document.lambda_efs.json
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_efs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_efs.arn
}

# resource "aws_efs_mount_target" "public" {
#   file_system_id  = aws_efs_file_system.efs_for_lambda.id
#   subnet_id       = var.public_subnet
#   security_groups = [aws_default_security_group.sg_for_lambda.id]
# }
#
output "efs_dns" {
  value = aws_efs_mount_target.alpha.dns_name
}

output "webserver_sg" {
  value = aws_security_group.sg_for_lambda.id
}

