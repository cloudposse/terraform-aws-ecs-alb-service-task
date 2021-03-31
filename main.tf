locals {
  enabled                 = module.this.enabled
  enable_ecs_service_role = module.this.enabled && var.network_mode != "awsvpc" && length(var.ecs_load_balancers) <= 1
}

module "task_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = local.enabled && length(var.task_role_arn) == 0

  attributes = ["task"]

  context = module.this.context
}

module "service_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = ["service"]

  context = module.this.context
}

module "exec_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  enabled = local.enabled && length(var.task_exec_role_arn) == 0

  attributes = ["exec"]

  context = module.this.context
}

resource "aws_ecs_task_definition" "default" {
  count                    = local.enabled && var.task_definition == null ? 1 : 0
  family                   = module.this.id
  container_definitions    = var.container_definition_json
  requires_compatibilities = [var.launch_type]
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = length(var.task_exec_role_arn) > 0 ? var.task_exec_role_arn : join("", aws_iam_role.ecs_exec.*.arn)
  task_role_arn            = length(var.task_role_arn) > 0 ? var.task_role_arn : join("", aws_iam_role.ecs_task.*.arn)

  dynamic "proxy_configuration" {
    for_each = var.proxy_configuration == null ? [] : [var.proxy_configuration]
    content {
      type           = lookup(proxy_configuration.value, "type", "APPMESH")
      container_name = proxy_configuration.value.container_name
      properties     = proxy_configuration.value.properties
    }
  }

  dynamic "placement_constraints" {
    for_each = var.task_placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  dynamic "volume" {
    for_each = var.volumes
    content {
      host_path = lookup(volume.value, "host_path", null)
      name      = volume.value.name

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id          = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", [])
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }
    }
  }

  tags = var.use_old_arn ? null : module.this.tags
}

# IAM
data "aws_iam_policy_document" "ecs_task" {
  count = local.enabled && length(var.task_role_arn) == 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task" {
  count = local.enabled && length(var.task_role_arn) == 0 ? 1 : 0

  name                 = module.task_label.id
  assume_role_policy   = join("", data.aws_iam_policy_document.ecs_task.*.json)
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = module.task_label.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  count      = local.enabled && length(var.task_role_arn) == 0 ? length(var.task_policy_arns) : 0
  policy_arn = var.task_policy_arns[count.index]
  role       = join("", aws_iam_role.ecs_task.*.id)
}


data "aws_iam_policy_document" "ecs_service" {
  count = local.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service" {
  count                = local.enable_ecs_service_role && var.service_role_arn == null ? 1 : 0
  name                 = module.service_label.id
  assume_role_policy   = join("", data.aws_iam_policy_document.ecs_service.*.json)
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = module.service_label.tags
}

data "aws_iam_policy_document" "ecs_service_policy" {
  count = local.enable_ecs_service_role && var.service_role_arn == null ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_service" {
  count  = local.enable_ecs_service_role && var.service_role_arn == null ? 1 : 0
  name   = module.service_label.id
  policy = join("", data.aws_iam_policy_document.ecs_service_policy.*.json)
  role   = join("", aws_iam_role.ecs_service.*.id)
}

data "aws_iam_policy_document" "ecs_ssm_exec" {
  count = local.enabled && var.exec_enabled ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_ssm_exec" {
  count  = local.enabled && var.exec_enabled ? 1 : 0
  name   = module.task_label.id
  policy = join("", data.aws_iam_policy_document.ecs_ssm_exec.*.json)
  role   = join("", aws_iam_role.ecs_task.*.id)
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "ecs_task_exec" {
  count = local.enabled && length(var.task_exec_role_arn) == 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_exec" {
  count                = local.enabled && length(var.task_exec_role_arn) == 0 ? 1 : 0
  name                 = module.exec_label.id
  assume_role_policy   = join("", data.aws_iam_policy_document.ecs_task_exec.*.json)
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = module.exec_label.tags
}

data "aws_iam_policy_document" "ecs_exec" {
  count = local.enabled && length(var.task_exec_role_arn) == 0 ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:GetParameters",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_exec" {
  count  = local.enabled && length(var.task_exec_role_arn) == 0 ? 1 : 0
  name   = module.exec_label.id
  policy = join("", data.aws_iam_policy_document.ecs_exec.*.json)
  role   = join("", aws_iam_role.ecs_exec.*.id)
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  count      = local.enabled && length(var.task_exec_role_arn) == 0 ? length(var.task_exec_policy_arns) : 0
  policy_arn = var.task_exec_policy_arns[count.index]
  role       = join("", aws_iam_role.ecs_exec.*.id)
}

# Service
## Security Groups
resource "aws_security_group" "ecs_service" {
  count       = local.enabled && var.network_mode == "awsvpc" ? 1 : 0
  vpc_id      = var.vpc_id
  name        = module.service_label.id
  description = "Allow ALL egress from ECS service"
  tags        = module.service_label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  count             = local.enabled && var.enable_all_egress_rule ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.ecs_service.*.id)
}

resource "aws_security_group_rule" "allow_icmp_ingress" {
  count             = local.enabled && var.enable_icmp_rule ? 1 : 0
  description       = "Enables ping command from anywhere, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html#sg-rules-ping"
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.ecs_service.*.id)
}

resource "aws_security_group_rule" "alb" {
  count                    = local.enabled && var.use_alb_security_group ? 1 : 0
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
  security_group_id        = join("", aws_security_group.ecs_service.*.id)
}

resource "aws_security_group_rule" "nlb" {
  count             = local.enabled && var.use_nlb_cidr_blocks ? 1 : 0
  type              = "ingress"
  from_port         = var.nlb_container_port
  to_port           = var.nlb_container_port
  protocol          = "tcp"
  cidr_blocks       = var.nlb_cidr_blocks
  security_group_id = join("", aws_security_group.ecs_service.*.id)
}

resource "aws_ecs_service" "ignore_changes_task_definition" {
  count                              = local.enabled && var.ignore_changes_task_definition ? 1 : 0
  name                               = module.this.id
  task_definition                    = coalesce(var.task_definition, "${join("", aws_ecs_task_definition.default.*.family)}:${join("", aws_ecs_task_definition.default.*.revision)}")
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = length(var.capacity_provider_strategies) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.scheduling_strategy
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  iam_role                           = local.enable_ecs_service_role ? coalesce(var.service_role_arn, join("", aws_iam_role.ecs_service.*.arn)) : null
  wait_for_steady_state              = var.wait_for_steady_state
  force_new_deployment               = var.force_new_deployment
  enable_execute_command             = var.exec_enabled

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategies
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = lookup(ordered_placement_strategy.value, "field", null)
    }
  }

  dynamic "placement_constraints" {
    for_each = var.service_placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  dynamic "load_balancer" {
    for_each = var.ecs_load_balancers
    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      elb_name         = lookup(load_balancer.value, "elb_name", null)
      target_group_arn = lookup(load_balancer.value, "target_group_arn", null)
    }
  }

  cluster        = var.ecs_cluster_arn
  propagate_tags = var.propagate_tags
  tags           = var.use_old_arn ? null : module.this.tags

  deployment_controller {
    type = var.deployment_controller_type
  }

  # https://www.terraform.io/docs/providers/aws/r/ecs_service.html#network_configuration
  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? ["true"] : []
    content {
      security_groups  = compact(concat(var.security_group_ids, aws_security_group.ecs_service.*.id))
      subnets          = var.subnet_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_ecs_service" "default" {
  count                              = local.enabled && var.ignore_changes_task_definition == false ? 1 : 0
  name                               = module.this.id
  task_definition                    = coalesce(var.task_definition, "${join("", aws_ecs_task_definition.default.*.family)}:${join("", aws_ecs_task_definition.default.*.revision)}")
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = length(var.capacity_provider_strategies) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.scheduling_strategy
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  iam_role                           = local.enable_ecs_service_role ? coalesce(var.service_role_arn, join("", aws_iam_role.ecs_service.*.arn)) : null
  wait_for_steady_state              = var.wait_for_steady_state
  force_new_deployment               = var.force_new_deployment
  enable_execute_command             = var.exec_enabled

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategies
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = lookup(ordered_placement_strategy.value, "field", null)
    }
  }

  dynamic "placement_constraints" {
    for_each = var.service_placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  dynamic "load_balancer" {
    for_each = var.ecs_load_balancers
    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      elb_name         = lookup(load_balancer.value, "elb_name", null)
      target_group_arn = lookup(load_balancer.value, "target_group_arn", null)
    }
  }

  cluster        = var.ecs_cluster_arn
  propagate_tags = var.propagate_tags
  tags           = var.use_old_arn ? null : module.this.tags

  deployment_controller {
    type = var.deployment_controller_type
  }

  # https://www.terraform.io/docs/providers/aws/r/ecs_service.html#network_configuration
  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? ["true"] : []
    content {
      security_groups  = compact(concat(var.security_group_ids, aws_security_group.ecs_service.*.id))
      subnets          = var.subnet_ids
      assign_public_ip = var.assign_public_ip
    }
  }
}
