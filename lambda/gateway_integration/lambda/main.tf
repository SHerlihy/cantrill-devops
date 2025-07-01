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

variable "rest_api_id" {
    type = string
}

variable "parent_id" {
    type = string
}

data "archive_file" "deployment" {
  type        = "zip"
  source_file = "${path.module}/deployment.py"
  output_path = "${path.module}/deployment.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "out_ip" {
  filename = data.archive_file.deployment.output_path
  handler = "deployment.lambda_handler"
  function_name = "out_ip"
  runtime = "python3.9"
  architectures = ["x86_64"]

  role = aws_iam_role.lambda_exec.arn
  timeout = 60
}

resource "aws_cloudwatch_log_group" "out_ip" {
  name = "/aws/lambda/${aws_lambda_function.out_ip.function_name}"

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

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_api_gateway_resource" "lambda" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "lambda"
}


resource "aws_api_gateway_method" "lambda_get" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_get" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method          = aws_api_gateway_method.lambda_get.http_method
  type                 = "AWS_PROXY"
  uri = aws_lambda_function.out_ip.invoke_arn
}

resource "aws_api_gateway_method_response" "lambda_get_200" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.lambda_get.http_method
  status_code = "200"
}

