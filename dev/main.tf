
# Dynamically discover the AWS Account ID of the caller.
data "aws_caller_identity" "current" {}

# Dynamically discover the AWS Region from the provider configuration.
data "aws_region" "current" {}

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
  source = "./modules/s3"
  
  bucket_name = "${var.s3_bucket_name_prefix}-${random_id.suffix.hex}"  
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

#      IAM module for a different purpose
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
  
  # Pass the discovered values into the module
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_region             = data.aws_region.current.name
  
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "lambda_kms_key" {
  source      = "./modules/kms"
  alias_name  = "lambda-env-key"
  description = "KMS key for encrypting Lambda environment variables"
  tags        = { Project = "CloudCostCalculator" }
}