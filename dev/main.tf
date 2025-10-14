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
  sender_email        = var.notification_email # Using the same email  for sender/receiver
  recipient_email     = var.notification_email
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

module "ses_email_identity" {
  source        = "./modules/ses"
  email_address = var.notification_email
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
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
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}

#   NEW LAMBDA FUNCTION FOR THE API 
module "get_cost_api_function" {
  source              = "./modules/lambda"
  function_name       = var.api_lambda_function_name
  iam_role_arn        = module.api_lambda_execution_role.role_arn
  source_code_path    = abspath("${path.root}/../src/lambda/get_cost_api/")
  
  # This Lambda is triggered by API Gateway, so schedule is null
  schedule_expression = null 

  # Environment variables are not needed for this one
  sender_email    = null
  recipient_email = null
  
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
  tags = {
    Project   = "CloudCostCalculator"
    ManagedBy = "Terraform"
  }
}