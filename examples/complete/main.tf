module "label" {
  source    = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=master"
  namespace = "eg"
  stage     = "staging"
  name      = "app"
}

module "container_definition" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=master"
  container_name  = "app"
  container_image = "cloudposse/geodesic"

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

module "alb_service_task" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-ecs-alb-service-task.git?ref=master"
  namespace                 = "eg"
  stage                     = "staging"
  name                      = "app"
  alb_target_group_arn      = "xxxxxxx"
  container_definition_json = "${module.container_definition.json}"
  container_name            = "${module.label.id}"
  ecs_cluster_arn           = "xxxxxxx"
  launch_type               = "FARGATE"
  vpc_id                    = "xxxxxxx"
  security_group_ids        = ["xxxxx", "yyyyy"]
  private_subnet_ids        = ["xxxxx", "yyyyy", "zzzzz"]
}
