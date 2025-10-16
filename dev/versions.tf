# environments/dev/providers.tf
terraform {
  backend "s3" {
    bucket       = "ysak-terraform-state-bucket"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }  
 # dev/versions.tf
}
# This block defines the version constraints for Terraform itself and its providers.
terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# The provider configuration block is separate and stands on its own.
provider "aws" {
  # The region is static for this project due to billing metrics.
  region = "us-east-1"
}