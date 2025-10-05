# dev/modules/ses/outputs.tf

output "identity_arn" {
  description = "The ARN of the SES email identity."
  value       = aws_ses_email_identity.this.arn
}