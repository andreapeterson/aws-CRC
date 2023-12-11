terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
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
