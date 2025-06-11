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

locals {
  lambda_name = "pixelator"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "source" {
  bucket_prefix = "pixelator.source"
}

resource "aws_s3_bucket" "pixelated" {
  bucket_prefix = "pixelator.pixelated"
}

resource "aws_lambda_function" "pixelator" {
  filename      = "deployment.zip"
  function_name = local.lambda_name
  role          = aws_iam_role.pixelator.arn
  handler       = "lambda_function.lambda_handler"
  architectures = ["x86_64"]
  layers        = [aws_lambda_layer_version.pillow.arn]

  runtime = "python3.9"

  timeout = 60

  environment {
    variables = {
      processed_bucket = aws_s3_bucket.pixelated.id
    }
  }
}

resource "aws_iam_role" "pixelator" {
  name = "pixelator"

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

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.source.arn,
      "${aws_s3_bucket.source.arn}/*",
      aws_s3_bucket.pixelated.arn,
      "${aws_s3_bucket.pixelated.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_name}:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3" {
  policy = data.aws_iam_policy_document.lambda_s3.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.pixelator.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.pixelator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "pixelator" {
  name = "/aws/lambda/${local.lambda_name}"

  retention_in_days = 30
}

resource "aws_lambda_layer_version" "pillow" {
  filename   = "pillow.zip"
  layer_name = "pillow"

  compatible_runtimes = ["python3.9"]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pixelator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pixelator.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
