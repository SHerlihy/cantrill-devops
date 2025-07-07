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

resource "aws_api_gateway_rest_api" "demo" {
  name        = "demo"
  description = "This is my API for demonstration purposes"
}

resource "aws_api_gateway_account" "demo" {
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

module "lambda" {
  source = "./lambda"

  rest_api_id = aws_api_gateway_rest_api.demo.id
  parent_id   = aws_api_gateway_rest_api.demo.root_resource_id
  gateway_execution_arn = aws_api_gateway_rest_api.demo.execution_arn 
}

module "sns" {
  source = "./sns"

  rest_api_id = aws_api_gateway_rest_api.demo.id
  parent_id   = aws_api_gateway_rest_api.demo.root_resource_id
}

resource "aws_api_gateway_resource" "mock" {
  rest_api_id = aws_api_gateway_rest_api.demo.id
  parent_id   = aws_api_gateway_rest_api.demo.root_resource_id
  path_part   = "mock"
}

resource "aws_api_gateway_method" "mock_get" {
  rest_api_id   = aws_api_gateway_rest_api.demo.id
  resource_id   = aws_api_gateway_resource.mock.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "mock_get" {
  rest_api_id = aws_api_gateway_rest_api.demo.id
  resource_id = aws_api_gateway_resource.mock.id
  http_method = aws_api_gateway_method.mock_get.http_method
  type        = "MOCK"
# overloaded to also be mock response
    request_templates = {
    "application/json" = <<TEMPLATE
{
  "statusCode": 200
}
TEMPLATE
  }
}

resource "aws_api_gateway_method_response" "mock_get_200" {
  rest_api_id = aws_api_gateway_rest_api.demo.id
  resource_id = aws_api_gateway_resource.mock.id
  http_method = aws_api_gateway_method.mock_get.http_method
  status_code = 200
}

resource "aws_api_gateway_integration_response" "mock_get" {
  depends_on = [
    aws_api_gateway_integration.mock_get
  ]

  rest_api_id = aws_api_gateway_rest_api.demo.id
  resource_id = aws_api_gateway_resource.mock.id

  http_method = aws_api_gateway_method.mock_get.http_method
  status_code = aws_api_gateway_method_response.mock_get_200.status_code

  response_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200,
  "message": "This response is mocking you"
}
EOF
  }
}
