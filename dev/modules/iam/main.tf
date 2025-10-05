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
# It grants access to Cost Explorer and allows writing logs to CloudWatch.
resource "aws_iam_policy" "lambda_permissions_policy" {
  name        = var.policy_name
  description = var.policy_description
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ce:GetCostAndUsage"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
       # This block grants the Lambda function permission to send emails
      # using the specified SES identity.
      {
        Effect   = "Allow",
        Action   = "ses:SendEmail",
        Resource = "arn:aws:ses:us-east-1:*:identity/*" # This is a reasonable scope
        # For stricter security in production, you could scope this down to the specific
        # identity ARN: "arn:aws:ses:us-east-1:ACCOUNT_ID:identity/your-email@example.com"
      }
    ]
  })
  tags = var.tags
}

# Attaches the permissions policy to the IAM role.
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions_policy.arn
}