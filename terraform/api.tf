# lambda function configuration
resource "aws_lambda_function" "lambda_function" {
  role             = "arn:aws:iam::877472877532:role/lambdaSagemakerFullAccess"
  handler          = "${var.handler}"
  runtime          = "${var.runtime}"
  filename         = "lambda.zip"
  function_name    = "${var.function_name}"
  
  environment {
    variables = {
      ENDPOINT_NAME = "${var.endpoint_name}"
    }
  }  
}

resource "aws_iam_role" "lambda_exec_role" {
  name        = "lambda_exec"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF  
}

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.lambda_function.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
 }

###########################
# api gateway configuration
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "SageMakerGatewy"
  description = "Access Amazon SageMaker REST Endpoint"
}

resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "POST"
   authorization = "NONE"
 }

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda_function.invoke_arn
 }

# proxy root
resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
   resource_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
   http_method   = "POST"
   authorization = "NONE"
 }

 resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda_function.invoke_arn
 }

resource "aws_api_gateway_deployment" "gateway_deployment" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
   stage_name  = "sagemaker"
 }

output "base_url" {
  value = aws_api_gateway_deployment.gateway_deployment.invoke_url
}
