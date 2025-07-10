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

variable "state_machine_arn" {
    type = string
}

resource "aws_api_gateway_rest_api" "cuddle" {
  name        = "cuddle"
  description = "This is my API for demonstration purposes"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_account" "cuddle" {
  cloudwatch_role_arn = aws_iam_role.gateway.arn
  reset_on_delete = true
}

data "aws_iam_policy_document" "gateway_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gateway" {
  assume_role_policy = data.aws_iam_policy_document.gateway_assume.json
}

resource "aws_iam_role_policy_attachment" "gateway_log" {
  role       = aws_iam_role.gateway.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

data "archive_file" "api_lambda" {
  type        = "zip"
  source_file = "${path.module}/api_lambda.py"
  output_path = "${path.module}/api_lambda.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "api_lambda" {
  filename = data.archive_file.api_lambda.output_path
  handler = "api_lambda.lambda_handler"
  function_name = "api_lambda"
  runtime = "python3.9"
  architectures = ["x86_64"]

  role = aws_iam_role.lambda_exec.arn


  environment {
    variables = {
      SM_ARN = var.state_machine_arn
    }
  }
}

resource "aws_cloudwatch_log_group" "api_lambda" {
  name = "/aws/lambda/${aws_lambda_function.api_lambda.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_state" {
  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      var.state_machine_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_state" {
  policy = data.aws_iam_policy_document.lambda_state.json
}

resource "aws_iam_role_policy_attachment" "lambda_state" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_state.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "gateway_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.api_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.cuddle.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "lambda" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  parent_id = aws_api_gateway_rest_api.cuddle.root_resource_id

  path_part   = "cuddle"
}

resource "aws_api_gateway_method" "lambda_post" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_post" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method          = aws_api_gateway_method.lambda_post.http_method
  integration_http_method = "POST"
  type                 = "AWS_PROXY"
  uri = aws_lambda_function.api_lambda.invoke_arn
}

resource "aws_api_gateway_integration_response" "lambda_post_200" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.lambda_post.http_method
  status_code = aws_api_gateway_method_response.lambda_post_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.lambda_post]
}

resource "aws_api_gateway_method_response" "lambda_post_200" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.lambda_post.http_method
  status_code = 200
    response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  resource_id   = aws_api_gateway_resource.lambda.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_mock]
}

resource "aws_api_gateway_deployment" "cuddle" {
  depends_on = [aws_api_gateway_integration.lambda_post]
  rest_api_id = aws_api_gateway_rest_api.cuddle.id
}

resource "aws_api_gateway_stage" "cuddle" {
  deployment_id = aws_api_gateway_deployment.cuddle.id
  rest_api_id   = aws_api_gateway_rest_api.cuddle.id
  stage_name    = "cuddle"
}

output "api_url" {
  value = "${aws_api_gateway_stage.cuddle.invoke_url}${aws_api_gateway_resource.lambda.path}"
}
