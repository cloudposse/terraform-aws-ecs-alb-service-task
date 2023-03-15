terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.40"
    }
    value = {
      source  = "pseudo-dynamic/value"
      version = ">= 0.5.5"
    }
  }
}
