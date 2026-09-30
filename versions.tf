terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state stored in S3, with DynamoDB used for state locking so
  # concurrent `terraform apply` runs cannot corrupt shared state.
  backend "s3" {
    bucket         = "descasio-shopzone-tfstate"
    key            = "shopzone/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "descasio-shopzone-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ShopZone"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Partner     = "Descasio"
    }
  }
}
