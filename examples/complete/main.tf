provider "aws" {
  version = ">= 2.22.0"
}

module "label" {
  source    = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=master"
  namespace = "eg"
  stage     = "staging"
  name      = "app"
}

module "container_definition" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=master"
  container_name  = "app"
  container_image = "cloudposse/geodesic:latest"

  environment = [
    {
      name  = "string_var"
      value = "I am a string"
    },
    {
      name  = "true_boolean_var"
      value = true
    },
    {
      name  = "false_boolean_var"
      value = false
    },
    {
      name  = "integer_var"
      value = 42
    },
  ]

  port_mappings = [
    {
      containerPort = 8080
      hostPort      = 80
      protocol      = "tcp"
    },
    {
      containerPort = 8081
      hostPort      = 443
      protocol      = "udp"
    },
  ]
}

// ECS service not tied to load balancer configs
module "alb_service_task_no_lb" {
  source                    = "../../"
  namespace                 = "eg"
  stage                     = "staging"
  name                      = "app"
  alb_security_group        = "xxxxxxx"
  container_definition_json = "${module.container_definition.json}"
  ecs_cluster_arn           = "xxxxxxx"
  launch_type               = "FARGATE"
  vpc_id                    = "xxxxxxx"
  security_group_ids        = ["xxxxx", "yyyyy"]
  subnet_ids                = ["xxxxx", "yyyyy", "zzzzz"]

  ignore_changes_task_definition = "true"
}

// ECS service ignoring task definition changes
module "alb_service_task_ignore" {
  source                    = "../../"
  namespace                 = "eg"
  stage                     = "staging"
  name                      = "app"
  alb_security_group        = "xxxxxxx"
  container_definition_json = "${module.container_definition.json}"
  ecs_cluster_arn           = "xxxxxxx"
  launch_type               = "FARGATE"
  vpc_id                    = "xxxxxxx"
  security_group_ids        = ["xxxxx", "yyyyy"]
  subnet_ids                = ["xxxxx", "yyyyy", "zzzzz"]

  ignore_changes_task_definition = "true"

  ecs_load_balancers = [
    {
      target_group_arn = "xxxxxxx"
      container_name   = "${module.label.id}"
      container_port   = "80"
    },
    {
      target_group_arn = "yyyyy"
      container_name   = "${module.label.id}"
      container_port   = "8080"
    },
  ]
}

// Default ECS service
module "alb_service_task" {
  source                    = "../../"
  namespace                 = "eg"
  stage                     = "staging"
  name                      = "app"
  alb_security_group        = "xxxxxxx"
  container_definition_json = "${module.container_definition.json}"
  ecs_cluster_arn           = "xxxxxxx"
  launch_type               = "FARGATE"
  vpc_id                    = "xxxxxxx"
  security_group_ids        = ["xxxxx", "yyyyy"]
  subnet_ids                = ["xxxxx", "yyyyy", "zzzzz"]

  ignore_changes_task_definition = "false"

  ecs_load_balancers = [
    {
      target_group_arn = "xxxxxxx"
      container_name   = "${module.label.id}"
      container_port   = "80"
    },
    {
      target_group_arn = "yyyyy"
      container_name   = "${module.label.id}"
      container_port   = "8080"
    },
  ]
}
