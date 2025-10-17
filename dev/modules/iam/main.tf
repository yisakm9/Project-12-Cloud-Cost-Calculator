# dev/modules/iam/main.tf

# Defines the IAM role and the trust relationship that allows the Lambda service to assume it.
resource "aws_iam_role" "lambda_exec_role" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

# Defines the permissions policy for our Lambda function.
resource "aws_iam_policy" "lambda_permissions_policy" {
  name        = var.policy_name
  description = var.policy_description
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      # Permission to read from Cost Explorer (read-only, "*" is acceptable here)
      {
        Effect   = "Allow",
        Action   = [
          "ce:GetCostAndUsage"
        ],
        Resource = "*"
      },
      # Permission to write logs to any log group
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      # Permission to send email from any verified identity in the region
      {
        Effect   = "Allow",
        Action   = "ses:SendEmail",
        Resource = "arn:aws:ses:us-east-1:*:identity/*"
      },
      # --- UPDATED PERMISSION BLOCK FOR DLQ ---
      # This conditionally grants permission to send messages ONLY to the specific SQS DLQ.
      # This resolves CKV_AWS_290 and CKV_AWS_355.
      {
        Sid      = "AllowSendMessageToDLQ",
        Effect   = var.sqs_dlq_arn != null ? "Allow" : "Deny", # Only allow if a DLQ ARN is provided
        Action   = "sqs:SendMessage",
        Resource = var.sqs_dlq_arn
      }
      # --- END UPDATE ---
    ]
  })
  tags = var.tags
}

# Attaches the permissions policy to the IAM role.
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions_policy.arn
}