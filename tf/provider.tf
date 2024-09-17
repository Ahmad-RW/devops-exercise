terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
  flux = {
    source  = "fluxcd/flux"
    version = ">= 1.2"
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}