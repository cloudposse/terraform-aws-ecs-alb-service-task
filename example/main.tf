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

variable "delimiter" {
  description = "The delimiter to be used in labels."
  default     = "-"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "attributes" {
  type        = "list"
  description = "List of attributes to add to label."
  default     = []
}

variable "tags" {
  type        = "map"
  description = "Map of Tag name/values."
  default     = {}
}

variable "region" {
  type        = "string"
  description = "AWS region"
}

variable "github_oauth_token" {
  description = "GitHub Oauth Token with permissions to access private repositories"
}

variable "repo_owner" {
  description = "GitHub Organization or Username."
}

variable "repo_name" {
  description = "GitHub repository name of the application to be built and deployed to ECS."
}

variable "branch" {
  description = "Branch of the GitHub repository, e.g. master"
}

provider "aws" {
  region = "${var.region}"
}

module "container_definition" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=0.1.3"
  container_name   = "${var.name}"
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
  alb_target_group_arn      = "${aws_lb_target_group.default.arn}"
  container_definition_json = "${module.container_definition.json}"
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
