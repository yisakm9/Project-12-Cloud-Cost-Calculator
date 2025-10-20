# dev/modules/kms/main.tf

# These data sources are needed to dynamically build the policy ARN.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# This data source constructs the IAM policy document in memory.
# Add suppression comments for the overly permissive root user policy.
#checkov:skip=CKV_AWS_109:Default root user access is an accepted risk for this project's key policy.
#checkov:skip=CKV_AWS_111:Default root user access is an accepted risk for this project's key policy.
#checkov:skip=CKV_AWS_356:Default root user access is an accepted risk for this project's key policy.
data "aws_iam_policy_document" "kms_policy" {
  # Statement 1: Default policy that gives the root user of the account full control over the key.
  statement {
    sid       = "EnableIAMUserPermissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Statement 2 (Conditional): If allow_cloudwatch_logs is true, add this statement.
  dynamic "statement" {
    for_each = var.allow_cloudwatch_logs ? [1] : []

    content {
      sid = "AllowCloudwatchLogsService"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"] 

      principals {
        type = "Service"
        
        identifiers = ["logs.${data.aws_region.current.id}.amazonaws.com"]
      }
    }
  }
}

# The KMS Key resource itself.
resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy.json
  tags                    = var.tags
}

# The alias for the KMS key, making it easier to reference.
resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias_name}"
  target_key_id = aws_kms_key.this.id
}