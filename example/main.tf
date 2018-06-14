terraform {
  required_version = ">= 0.11.2"
}

provider "aws" {
  region = "${var.region}"
}

module "example_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.1.2"
  attributes = "${var.attributes}"
  delimiter  = "${var.delimiter}"
  name       = "${var.name}"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  tags       = "${var.tags}"
}

# ECR Repository
module "ecr" {
  source     = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=master"
  name       = "${var.name}"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  attributes = "${compact(concat(var.attributes, list("ecr")))}"
}

# ECS Cluster (needed even if using FARGATE launch type
resource "aws_ecs_cluster" "default" {
  name = "${module.example_label.id}"
}

# Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name = "${module.example_label.id}"
  tags = "${module.example_label.tags}"
}

module "alb" {
  source             = "git::https://github.com/cloudposse/terraform-aws-alb.git?ref=init"
  name               = "${var.name}"
  namespace          = "${var.namespace}"
  stage              = "${var.stage}"
  attributes         = "${compact(concat(var.attributes, list("alb")))}"
  vpc_id             = "${module.vpc.vpc_id}"
  ip_address_type    = "ipv4"
  subnet_ids         = ["${module.dynamic_subnets.public_subnet_ids}"]
  security_group_ids = ["${module.vpc.vpc_default_security_group_id}"]
  access_logs_region = "us-west-2"
}

module "alb_ingress" {
  source        = "git::https://github.com/cloudposse/terraform-aws-alb-ingress.git?ref=init"
  name          = "${var.name}"
  namespace     = "${var.namespace}"
  stage         = "${var.stage}"
  attributes    = "${compact(concat(var.attributes, list("alb", "ingress")))}"
  vpc_id        = "${module.vpc.vpc_id}"
  listener_arns = "${module.alb.listener_arns}"
}

module "container_definition" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=0.1.3"
  container_name   = "${module.example_label.id}"
  container_image  = "nginx:latest"
  container_memory = 128
  container_port   = 80

  log_options = {
    "awslogs-region"        = "${var.region}"
    "awslogs-group"         = "${aws_cloudwatch_log_group.app.name}"
    "awslogs-stream-prefix" = "${var.name}"
  }
}

module "ecs_alb_service_task" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-ecs-alb-service-task.git?ref=0.1.0"
  name                      = "${var.name}"
  namespace                 = "${var.namespace}"
  stage                     = "${var.stage}"
  alb_target_group_arn      = "${module.alb_ingress.target_group_arn}"
  container_definition_json = "${module.container_definition.json}"
  container_name            = "${module.example_label.id}"
  ecr_repository_name       = "${module.ecr.repository_name}"
  ecs_cluster_arn           = "${aws_ecs_cluster.default.arn}"
  launch_type               = "FARGATE"
  vpc_id                    = "${module.vpc.vpc_id}"
  security_group_ids        = ["${module.vpc.vpc_default_security_group_id}"]
  private_subnet_ids        = "${module.dynamic_subnets.private_subnet_ids}"
}

module "ecs_codepipeline" {
  source             = "git::https://github.com/cloudposse/terraform-aws-ecs-codepipeline.git?ref=0.1.0"
  name               = "${var.name}"
  namespace          = "${var.namespace}"
  stage              = "${var.stage}"
  github_oauth_token = "${var.github_oauth_token}"
  repo_owner         = "${var.repo_owner}"
  repo_name          = "${var.repo_name}"
  branch             = "${var.branch}"
  service_name       = "${module.ecs_alb_service_task.service_name}"
  ecs_cluster_name   = "${aws_ecs_cluster.default.name}"
  privileged_mode    = "true"
}
