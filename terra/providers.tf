terraform {
  required_version = ">= 1.5.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terra444"
    key    = "my-terraform-project"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.REGION
}
