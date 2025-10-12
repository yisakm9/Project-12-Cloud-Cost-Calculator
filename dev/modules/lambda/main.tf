#  dev/modules/lambda/main.tf

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_code_path
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "cost_report_lambda" {
  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role          = var.iam_role_arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SENDER_EMAIL    = var.sender_email
      RECIPIENT_EMAIL = var.recipient_email
    }
  }

  timeout     = 120
  memory_size = 128
  tags        = var.tags
}
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.function_name}-schedule"
  description         = "Triggers the cost report Lambda function"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count     = var.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.lambda_schedule[0].name
  target_id = var.function_name
  arn       = aws_lambda_function.cost_report_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.schedule_expression != null ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_report_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule[0].arn
}