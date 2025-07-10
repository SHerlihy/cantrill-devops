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
  lambda_name = "messager"
}

data "aws_caller_identity" "current" {}

resource "aws_ses_email_identity" "sender" {
  email = "steven0herlihy+cuddle-app-sender@gmail.com"
}

resource "aws_ses_email_identity" "receiver" {
  email = "steven0herlihy+cuddle-app-receiver@gmail.com"
}

data "archive_file" "messager_app" {
  type             = "zip"
  source_file      = "${path.module}/deployment.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/deployment.zip"
}

resource "aws_lambda_function" "messager" {
  filename      = data.archive_file.messager_app.output_path
  function_name = local.lambda_name
  role          = aws_iam_role.messager.arn
  handler       = "deployment.lambda_handler"
  architectures = ["x86_64"]

  runtime = "python3.9"

  environment {
    variables = {
      FROM_EMAIL_ADDRESS = aws_ses_email_identity.sender.email
    }
  }
}

resource "aws_cloudwatch_log_group" "messager" {
  name = "/aws/lambda/${local.lambda_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "messager" {
  name = "messager"

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

data "aws_iam_policy_document" "messaging" {
  statement {
    effect = "Allow"
    actions = [
      "ses:*",
      "sms:*"
    ]
    resources = [
      "arn:aws:ses:us-east-1:${data.aws_caller_identity.current.account_id}:*",
      "arn:aws:sms:us-east-1:${data.aws_caller_identity.current.account_id}:*"
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

resource "aws_iam_policy" "lambda_messaging" {
  policy = data.aws_iam_policy_document.messaging.json
}

resource "aws_iam_role_policy_attachment" "messaging" {
  role       = aws_iam_role.messager.name
  policy_arn = aws_iam_policy.lambda_messaging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.messager.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "states" {
  name = "states"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "states.amazonaws.com"
      }
      }
    ]
  })
}

data "aws_iam_policy_document" "states" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "sns:*"
    ]
    resources = [
      aws_lambda_function.messager.arn,
      "arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "states" {
  policy = data.aws_iam_policy_document.states.json
}

resource "aws_iam_role_policy_attachment" "states" {
  role       = aws_iam_role.states.name
  policy_arn = aws_iam_policy.states.arn
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.states.arn

  definition = <<EOF
{
  "Comment": "Pet Cuddle-o-Tron - using Lambda for email.",
  "StartAt": "Timer",
  "States": {
    "Timer": {
      "Type": "Wait",
      "SecondsPath": "$.waitSeconds",
      "Next": "Email"
    },
    "Email": {
      "Type" : "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.messager.arn}",
        "Payload": {
          "Input.$": "$"
        }
      },
      "Next": "NextState"
    },
    "NextState": {
      "Type": "Pass",
      "End": true
    }
  }
}
EOF
}

output "state_machine_arn" {
    value = aws_sfn_state_machine.sfn_state_machine.arn
}
