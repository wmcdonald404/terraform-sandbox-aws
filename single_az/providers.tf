terraform {
  # backend "local" {
  # }
  required_version = ">= 1.8.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.51.1"
    }
  }
}

provider "aws" {
  region = var.region
}
