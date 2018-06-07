module "ecr" {
  source    = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=master"
  name      = "${var.name}"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
}

resource "aws_ecs_cluster" "default" {
  name = "${var.name}"
}
