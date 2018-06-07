terraform {
  required_version = ">= 0.11.2"
}

variable "name" {
  type        = "string"
  description = "Name (unique identifier for app or service)"
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

provider "aws" {
  region = "${var.region}"
}

module "container_definition" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=master"
  container_name   = "${var.name}"
  container_image  = "nginx:latest"
  container_memory = 128
  container_port   = 80

  log_options = {
    "awslogs-region" = "${var.region}"

    "awslogs-group" = "${aws_cloudwatch_log_group.app.name}"

    "awslogs-stream-prefix" = "${var.name}"
  }
}

module "ecs-alb-service-task" {
  #source                    = "git::https://github.com/cloudposse/terraform-aws-ecs-alb-service-task.git?ref=master"
  source                    = "../"
  name                      = "${var.name}"
  namespace                 = "${var.namespace}"
  stage                     = "${var.stage}"
  alb_arn                   = "${aws_lb.default.arn}"
  container_definition_json = "${module.container_definition.json}"
  ecr_repository_name       = "${module.ecr.repository_name}"
  ecs_cluster_arn           = "${aws_ecs_cluster.default.arn}"
  launch_type               = "FARGATE"
  vpc_id                    = "${module.vpc.vpc_id}"
  security_group_ids        = ["${module.vpc.vpc_default_security_group_id}"]
  private_subnet_ids        = "${module.dynamic_subnets.private_subnet_ids}"
}
