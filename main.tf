module "default_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  attributes = var.attributes
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
}

module "task_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  attributes = [compact(concat(var.attributes, ["task"]))]
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
}

module "service_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  attributes = [compact(concat(var.attributes, ["service"]))]
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
}

module "exec_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  attributes = [compact(concat(var.attributes, ["exec"]))]
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
}

resource "aws_ecs_task_definition" "default" {
  family                   = module.default_label.id
  container_definitions    = var.container_definition_json
  requires_compatibilities = [var.launch_type]
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  tags                     = module.default_label.tags
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
    }
  }
}

# IAM
data "aws_iam_policy_document" "ecs_task" {
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
  name               = module.task_label.id
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
  tags               = module.task_label.tags
}

data "aws_iam_policy_document" "ecs_service" {
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
  name               = module.service_label.id
  assume_role_policy = data.aws_iam_policy_document.ecs_service.json
  tags               = module.service_label.tags
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_service" {
  name   = module.service_label.id
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_service.id
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_exec" {
  name               = module.exec_label.id
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec.json
  tags               = module.exec_label.tags
}

data "aws_iam_policy_document" "ecs_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_exec" {
  name   = module.exec_label.id
  policy = data.aws_iam_policy_document.ecs_exec.json
  role   = aws_iam_role.ecs_exec.id
}

# Service
## Security Groups
resource "aws_security_group" "ecs_service" {
  vpc_id      = var.vpc_id
  name        = module.service_label.id
  description = "Allow ALL egress from ECS service"
  tags        = module.service_label.tags
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

resource "aws_security_group_rule" "allow_icmp_ingress" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

resource "aws_security_group_rule" "alb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
  security_group_id        = aws_security_group.ecs_service.id
}

resource "aws_ecs_service" "ignore_changes_task_definition" {
  count                              = var.ignore_changes_task_definition == "true" ? 1 : 0
  name                               = module.default_label.id
  task_definition                    = "${aws_ecs_task_definition.default.family}:${aws_ecs_task_definition.default.revision}"
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = var.launch_type
  cluster                            = var.ecs_cluster_arn
  tags                               = module.default_label.tags

  deployment_controller {
    type = var.deployment_controller_type
  }

  network_configuration {
    security_groups  = [var.security_group_ids, aws_security_group.ecs_service.id]
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_ecs_service" "default" {
  count                              = var.ignore_changes_task_definition == "false" ? 1 : 0
  name                               = module.default_label.id
  task_definition                    = "${aws_ecs_task_definition.default.family}:${aws_ecs_task_definition.default.revision}"
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = var.launch_type
  cluster                            = var.ecs_cluster_arn
  tags                               = module.default_label.tags

  deployment_controller {
    type = var.deployment_controller_type
  }

  network_configuration {
    security_groups  = [var.security_group_ids, aws_security_group.ecs_service.id]
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

