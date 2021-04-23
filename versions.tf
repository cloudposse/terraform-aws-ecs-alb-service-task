terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.34"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
  }
}

