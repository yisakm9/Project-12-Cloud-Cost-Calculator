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
  sender_email        = var.notification_email # Using the same email for sender/receiver
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