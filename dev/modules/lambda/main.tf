# dev/modules/lambda/main.tf

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_code_path
  output_path = "${path.module}/${var.function_name}.zip"
}

# CKV_AWS_116: Dead Letter Queue (DLQ) for capturing failed Lambda invocations.
resource "aws_sqs_queue" "lambda_dlq" {
  count             = var.function_name != null ? 1 : 0
  name              = "${var.function_name}-dlq"
  # CKV_AWS_27: Add server-side encryption
  kms_master_key_id = "alias/aws/sqs"
  tags              = var.tags
}

# This is the main Lambda function resource with security hardening.
# Add suppressions with comments
#checkov:skip=CKV_AWS_117:Function does not require VPC access
#checkov:skip=CKV_AWS_115:Concurrency limit is not a critical requirement for this project
#checkov:skip=CKV_AWS_272:Code signing is overkill for this low-risk internal function
resource "aws_lambda_function" "this" {
  # Suppress non-applicable Checkov findings with inline comments.
  # CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC" - Not needed, function only calls public APIs.
  # CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit" - Low risk for this project.
  # CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing" - Overkill for this project's scope.

  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role          = var.iam_role_arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # CKV_AWS_116: Configure the DLQ.
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq[0].arn
  }

  # CKV_AWS_50: Enable X-Ray active tracing for observability.
  tracing_config {
    mode = "Active"
  }

  # Use the generic map for environment variables.
  environment {
    variables = var.environment_variables
  }
  
  # CKV_AWS_173: Encrypt environment variables at rest using the provided KMS key.
  kms_key_arn = var.kms_key_arn

  timeout     = 120
  memory_size = 128
  tags        = var.tags
}

# --- Resources for Scheduled (Cron) Triggers ---

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  # Only create this resource if a schedule expression is provided.
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.function_name}-schedule"
  description         = "Triggers the Lambda function on a schedule"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  # Only create this resource if a schedule is provided.
  count     = var.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.lambda_schedule[0].name
  target_id = var.function_name
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  # Only create this resource if a schedule is provided.
  count         = var.schedule_expression != null ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule[0].arn
}