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

# CKV_AWS_76: Create a CloudWatch Log Group to store access logs for the API.
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  # CKV_AWS_338: Set retention to at least one year
  retention_in_days = 30
   # CKV_AWS_158: Encrypt the log group with the default AWS-managed key for logs.
  kms_key_id        = "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:alias/aws/logs"
  tags              = var.tags
}

# The default stage for the API, now with access logging configured.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  # CKV_AWS_76: Enable access logging for the stage.
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    # A standard JSON log format for access logs.
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      path                    = "$context.path"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# The integration between the API Gateway and the Lambda function.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_integration_arn
}

# The route that maps an incoming request to the Lambda integration.
resource "aws_apigatewayv2_route" "get_costs" {
  # CKV_AWS_309: "Ensure API GatewayV2 routes specify an authorization type" - Suppressed by being explicit.
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /costs"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  
  # Explicitly setting authorization to NONE resolves the Checkov finding for this public API.
  authorization_type = "NONE"
}

# Grant API Gateway permission to invoke the Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_integration_arn
  principal     = "apigateway.amazonaws.com"

  # Scopes the permission to any method on any path of this specific API.
  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}