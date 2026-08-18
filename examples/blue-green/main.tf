provider "aws" {
  region = var.region
}

locals {
  enabled = module.this.enabled
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  ipv4_primary_cidr_block = var.vpc_cidr_block

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.4.2"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this.context
}

resource "aws_ecs_cluster" "default" {
  #bridgecrew:skip=BC_AWS_LOGGING_11: not required for testing
  count = local.enabled ? 1 : 0
  name  = module.this.id
  tags  = module.this.tags
}

module "container_definition" {
  count = local.enabled ? 1 : 0

  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.2"

  container_name               = var.container_name
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.container_cpu
  essential                    = var.container_essential
  readonly_root_filesystem     = var.container_readonly_root_filesystem
  environment                  = var.container_environment
  port_mappings                = var.container_port_mappings
}

module "test_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "0.4.0"

  name       = "policy"
  attributes = ["test"]

  iam_policy_enabled = true
  description        = "Test policy"

  iam_policy_statements = [
    {
      sid        = "DummyStatement"
      effect     = "Allow"
      actions    = ["none:null"]
      resources  = ["*"]
      conditions = []
    }
  ]

  context = module.this.context
}

# --- Native ECS blue/green deployment supporting infrastructure ---
# Blue/green needs a production ("blue") target group, an alternate ("green") target
# group, and a production listener rule whose forward action references BOTH (ECS shifts
# the weights during a deployment). An optional test listener rule routes test traffic to
# the green revision before production traffic is shifted.

# ALB + default ("blue") target group + HTTP listener via the first-party module.
module "alb" {
  source  = "cloudposse/alb/aws"
  version = "2.5.0"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.subnets.public_subnet_ids
  target_group_port   = var.blue_green_container_port
  health_check_path   = "/"
  access_logs_enabled = false

  context = module.this.context
}

# Alternate ("green") target group that ECS routes to during a blue/green deployment.
resource "aws_lb_target_group" "alternate" {
  count = local.enabled ? 1 : 0

  name_prefix = "bgalt"
  port        = var.blue_green_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  tags = module.this.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Production listener rule forwarding to BOTH target groups (weights managed by ECS).
resource "aws_lb_listener_rule" "blue_green" {
  count = local.enabled ? 1 : 0

  listener_arn = module.alb.http_listener_arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = module.alb.default_target_group_arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.alternate[0].arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = module.this.tags
}

# Optional test listener rule that routes test traffic to the green revision.
resource "aws_lb_listener_rule" "blue_green_test" {
  count = local.enabled ? 1 : 0

  listener_arn = module.alb.http_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alternate[0].arn
  }

  condition {
    path_pattern {
      values = ["/test/*"]
    }
  }

  tags = module.this.tags
}

# IAM role that allows ECS to manage the target groups / listener rules during rollout.
resource "aws_iam_role" "ecs_blue_green" {
  count = local.enabled ? 1 : 0

  name_prefix = "ecs-bg-"
  tags        = module.this.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_blue_green" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.ecs_blue_green[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}

module "ecs_alb_service_task" {
  source                             = "../.."
  alb_security_group                 = local.enabled ? module.alb.security_group_id : module.vpc.vpc_default_security_group_id
  use_alb_security_group             = true
  container_port                     = var.blue_green_container_port
  container_definition_json          = one(module.container_definition.*.json_map_encoded_list)
  ecs_cluster_arn                    = one(aws_ecs_cluster.default.*.id)
  launch_type                        = var.ecs_launch_type
  vpc_id                             = module.vpc.vpc_id
  security_group_ids                 = [module.vpc.vpc_default_security_group_id]
  subnet_ids                         = module.subnets.public_subnet_ids
  ignore_changes_task_definition     = var.ignore_changes_task_definition
  network_mode                       = var.network_mode
  assign_public_ip                   = var.assign_public_ip
  propagate_tags                     = var.propagate_tags
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type         = var.deployment_controller_type
  desired_count                      = var.desired_count
  task_memory                        = var.task_memory
  task_cpu                           = var.task_cpu
  ecs_service_enabled                = var.ecs_service_enabled
  force_new_deployment               = var.force_new_deployment
  redeploy_on_apply                  = var.redeploy_on_apply
  task_policy_arns                   = [module.test_policy.policy_arn]
  task_exec_policy_arns_map          = { test = module.test_policy.policy_arn }

  ecs_load_balancers = local.enabled ? [
    {
      container_name   = var.container_name
      container_port   = var.blue_green_container_port
      elb_name         = null
      target_group_arn = module.alb.default_target_group_arn
      advanced_configuration = {
        alternate_target_group_arn = aws_lb_target_group.alternate[0].arn
        production_listener_rule   = aws_lb_listener_rule.blue_green[0].arn
        test_listener_rule         = aws_lb_listener_rule.blue_green_test[0].arn
        role_arn                   = aws_iam_role.ecs_blue_green[0].arn
      }
    }
  ] : []

  deployment_configuration = local.enabled ? {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = 3
  } : null

  context = module.this.context
}
