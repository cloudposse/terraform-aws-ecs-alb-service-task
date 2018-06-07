terraform {
  required_version = ">= 0.11.2"
}

provider "aws" {}

variable "aws_assume_role_arn" {
  type = "string"
}

variable "namespace" {
  type        = "string"
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "region" {
  type        = "string"
  description = "AWS region"
}
