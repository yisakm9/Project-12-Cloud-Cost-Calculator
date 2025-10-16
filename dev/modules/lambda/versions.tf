# This file defines the required provider versions for the Lambda module.

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # Explicitly declare the 'archive' provider
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}