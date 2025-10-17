# dev/modules/sns/main.tf
# CKV_AWS_26: Add server-side encryption
resource "aws_sns_topic" "this" {
  name = var.topic_name
  tags = var.tags
  kms_master_key_id = "alias/aws/sns" # Use the AWS-managed key
  
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}