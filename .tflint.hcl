plugin "aws" {
  enabled = true
  version = "0.23.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  version = "0.3.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["any"]
}
