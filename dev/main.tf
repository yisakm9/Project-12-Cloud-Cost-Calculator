
resource "random_id" "suffix" {
  byte_length = 4 # Generates an 8-character hex string
}

module "cost_alerting_topic" {
  source       = "./modules/sns"
  topic_name   = var.sns_topic_name
  email_endpoint = var.notification_email
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "billing_alarm" {
  source        = "./modules/cloudwatch"
  threshold     = var.billing_alarm_threshold
  sns_topic_arn = module.cost_alerting_topic.topic_arn
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "lambda_execution_role" {
  source      = "./modules/iam"
  role_name   = var.lambda_iam_role_name
  policy_name = "${var.lambda_iam_role_name}-policy"
  sqs_dlq_arn = module.cost_report_function.dlq_arn
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "cost_report_function" {
  source              = "./modules/lambda"
  function_name       = var.lambda_function_name
  iam_role_arn        = module.lambda_execution_role.role_arn
  source_code_path    = abspath("${path.root}/../src/lambda/get_cost_report/")
  depends_on          = [module.ses_email_identity]
  schedule_expression = var.lambda_schedule
  kms_key_arn         = module.lambda_kms_key.key_arn
  sqs_kms_key_arn = module.sqs_kms_key.key_arn
  
  environment_variables = {
    SENDER_EMAIL    = var.notification_email
    RECIPIENT_EMAIL = var.notification_email
  }
  
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "ses_email_identity" {
  source        = "./modules/ses"
  email_address = var.notification_email
  # tags = {
  # Project   = "CloudCostCalculator"
  #   ManagedBy = "Terraform"
  # }
}

module "cost_dashboard_bucket" {
  source                 = "./modules/s3"
  bucket_name            = "${var.s3_bucket_name_prefix}-${random_id.suffix.hex}"  
  logging_bucket_id      = aws_s3_bucket.logging_bucket.id

  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}
#  IAM module for a different purpose
module "api_lambda_execution_role" {
  source      = "./modules/iam"
  role_name   = var.api_lambda_iam_role_name
  policy_name = "${var.api_lambda_iam_role_name}-policy"
  sqs_dlq_arn = module.get_cost_api_function.dlq_arn
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

# NEW LAMBDA FUNCTION FOR THE API 
module "get_cost_api_function" {
  source              = "./modules/lambda"
  function_name       = var.api_lambda_function_name
  iam_role_arn        = module.api_lambda_execution_role.role_arn
  source_code_path    = abspath("${path.root}/../src/lambda/get_cost_api/")
  kms_key_arn         = module.lambda_kms_key.key_arn
  sqs_kms_key_arn     = module.sqs_kms_key.key_arn
  schedule_expression = null 
  
  # The invalid arguments are removed.
  # No `environment_variables` argument is needed because the default empty map is sufficient.
  
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}
#  NEW API GATEWAY RESOURCE 
module "cost_api" {
  source                 = "./modules/apigateway"
  api_name               = var.api_name
  lambda_integration_arn = module.get_cost_api_function.function_arn
  
  
  log_group_kms_key_arn  = module.logs_kms_key.key_arn
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "lambda_kms_key" {
  source      = "./modules/kms"
  alias_name  = "lambda-env-key"
  description = "KMS key for encrypting Lambda environment variables"
  # allow_cloudwatch_logs is false by default, which is correct for this key.
  tags = { Project = "CloudCostCalculator" }
}

module "logs_kms_key" {
  source      = "./modules/kms"
  alias_name  = "cloudwatch-logs-key"
  description = "KMS key for encrypting CloudWatch log groups"
  
  # Explicitly enable the policy statement for CloudWatch Logs.
  allow_cloudwatch_logs = true
  
  tags = { Project = "CloudCostCalculator" }
}
module "sqs_kms_key" {
  source      = "./modules/kms"
  alias_name  = "sqs-dlq-key"
  description = "KMS key for encrypting SQS DLQs"
  tags        = { Project = "CloudCostCalculator" }
}

# Create the CloudFront distribution
module "cloudfront_distribution" {
  source                         = "./modules/cloudfront"
  s3_bucket_regional_domain_name = module.cost_dashboard_bucket.bucket_regional_domain_name
  logging_bucket_domain_name     = aws_s3_bucket.logging_bucket.bucket_regional_domain_name
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }

  # Explicitly tell Terraform to create the S3 bucket before the CloudFront distribution
  depends_on = [module.cost_dashboard_bucket]
}

# --- ADD THIS NEW RESOURCE BLOCK ---
# This bucket policy is now in the root module, where it can access outputs
# from both the S3 and CloudFront modules, breaking the dependency cycle.
# It lives in the root module to break the dependency cycle.
resource "aws_s3_bucket_policy" "dashboard_bucket_policy" {
  bucket = module.cost_dashboard_bucket.bucket_name
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontOAI",
        Effect    = "Allow",
        Principal = {
          # It gets the OAI ARN from the CloudFront module's output
          AWS = module.cloudfront_distribution.oai_iam_arn
        },
        Action    = "s3:GetObject",
        # It gets the bucket ARN from the S3 module's output
        Resource  = "${module.cost_dashboard_bucket.bucket_arn}/*"
      }
    ]
  })
}
# --- ADD THIS NEW S3 BUCKET FOR LOGS ---
resource "aws_s3_bucket" "logging_bucket" {
  #checkov:skip=CKV_AWS_18:This is the logging bucket, it cannot log to itself.
  #checkov:skip=CKV_AWS_21:Versioning is not required for a log bucket.
  #checkov:skip=CKV_AWS_145:Default encryption is sufficient for this log bucket.
  bucket = "cost-calculator-logs-${random_id.suffix.hex}"
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}
# 1. Ownership Controls: Set the object ownership to 'BucketOwnerPreferred'.
# This is a prerequisite for enabling ACLs for this use case.
resource "aws_s3_bucket_ownership_controls" "logging_bucket_oc" {
  bucket = aws_s3_bucket.logging_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 2. ACL Configuration: Explicitly set the ACL to 'private'.
# This enables ACLs on the bucket, which is required by the CloudFront logging service.
resource "aws_s3_bucket_acl" "logging_bucket_acl" {
  bucket = aws_s3_bucket.logging_bucket.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.logging_bucket_oc]
}
resource "aws_s3_bucket_public_access_block" "logging_bucket_pab" {
  bucket = aws_s3_bucket.logging_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}