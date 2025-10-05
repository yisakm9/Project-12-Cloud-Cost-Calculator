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