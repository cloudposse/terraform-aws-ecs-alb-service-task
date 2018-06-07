# ECR Repository
module "ecr" {
  source    = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=master"
  name      = "${var.name}"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
}

# ECS Cluster (needed even if using FARGATE launch type
resource "aws_ecs_cluster" "default" {
  name = "${var.name}"
}

# Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name = "${var.name}-${var.stage}"

  tags {
    Stage       = "${var.stage}"
    Application = "${var.name}"
  }
}
