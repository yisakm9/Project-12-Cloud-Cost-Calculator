# dev/modules/apigateway/main.tf

resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
  
  # Professional Practice: Explicitly define CORS. For this project, '*' is fine.
  # In production, you would restrict this to your specific S3 website domain.
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["*"]
  }
  
  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_integration_arn
}

resource "aws_apigatewayv2_route" "get_costs" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /costs"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_integration_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}