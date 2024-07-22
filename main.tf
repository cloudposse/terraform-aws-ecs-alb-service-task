locals {
  enabled                         = module.this.enabled
  ecs_service_enabled             = local.enabled && var.ecs_service_enabled
  task_role_arn                   = try(var.task_role_arn[0], tostring(var.task_role_arn), "")
  create_task_role                = local.enabled && length(var.task_role_arn) == 0
  task_exec_role_arn              = try(var.task_exec_role_arn[0], tostring(var.task_exec_role_arn), "")
  create_exec_role                = local.enabled && length(var.task_exec_role_arn) == 0
  enable_ecs_service_role         = module.this.enabled && var.network_mode != "awsvpc" && length(var.ecs_load_balancers) >= 1
  create_service_connect_tls_role = local.enabled && length(flatten(flatten(var.service_connect_configurations[*].service[*].tls[*]))) > 0 && length(compact(flatten(flatten(var.service_connect_configurations[*].service[*].tls[*].role_arn)))) == 0
  create_security_group           = local.enabled && var.network_mode == "awsvpc" && var.security_group_enabled
  create_task_definition          = local.enabled && length(var.task_definition) == 0

  volumes = concat(var.docker_volumes, var.efs_volumes, var.fsx_volumes, var.bind_mount_volumes)

  redeployment_trigger = var.force_new_deployment && var.redeploy_on_apply ? {
    redeployment = timestamp()
  } : {}

  task_policy_arns_map = merge({ for i, a in var.task_policy_arns : format("_#%v_", i) => a }, var.task_policy_arns_map)

  task_exec_policy_arns_map = merge({ for i, a in var.task_exec_policy_arns : format("_#%v_", i) => a }, var.task_exec_policy_arns_map)
}

module "task_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  enabled    = local.create_task_role
  attributes = ["task"]

  context = module.this.context
}

module "service_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["service"]

  context = module.this.context
}

module "exec_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  enabled    = local.create_exec_role
  attributes = ["exec"]

  context = module.this.context
}

module "service_connect_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  enabled    = local.create_service_connect_tls_role
  attributes = ["service-connect-tls"]

  context = module.this.context
}

resource "aws_ecs_task_definition" "default" {
  count                    = local.create_task_definition ? 1 : 0
  family                   = module.this.id
  container_definitions    = var.container_definition_json
  requires_compatibilities = [var.launch_type]
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  ipc_mode                 = var.ipc_mode
  pid_mode                 = var.pid_mode
  execution_role_arn       = length(local.task_exec_role_arn) > 0 ? local.task_exec_role_arn : one(aws_iam_role.ecs_exec[*]["arn"])
  task_role_arn            = length(local.task_role_arn) > 0 ? local.task_role_arn : one(aws_iam_role.ecs_task[*]["arn"])
  track_latest             = var.track_latest

  dynamic "proxy_configuration" {
    for_each = var.proxy_configuration == null ? [] : [var.proxy_configuration]
    content {
      type           = lookup(proxy_configuration.value, "type", "APPMESH")
      container_name = proxy_configuration.value.container_name
      properties     = proxy_configuration.value.properties
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size == 0 ? [] : [var.ephemeral_storage_size]
    content {
      size_in_gib = var.ephemeral_storage_size
    }
  }

  dynamic "placement_constraints" {
    for_each = var.task_placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  dynamic "runtime_platform" {
    for_each = var.runtime_platform
    content {
      operating_system_family = lookup(runtime_platform.value, "operating_system_family", null)
      cpu_architecture        = lookup(runtime_platform.value, "cpu_architecture", null)
    }
  }

  dynamic "volume" {
    for_each = local.volumes
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

      dynamic "fsx_windows_file_server_volume_configuration" {
        for_each = lookup(volume.value, "fsx_windows_file_server_volume_configuration", [])
        content {
          file_system_id = lookup(fsx_windows_file_server_volume_configuration.value, "file_system_id", null)
          root_directory = lookup(fsx_windows_file_server_volume_configuration.value, "root_directory", null)
          dynamic "authorization_config" {
            for_each = lookup(fsx_windows_file_server_volume_configuration.value, "authorization_config", [])
            content {
              credentials_parameter = lookup(authorization_config.value, "credentials_parameter", null)
              domain                = lookup(authorization_config.value, "domain", null)
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
  count = local.create_task_role ? 1 : 0

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
  count = local.create_task_role ? 1 : 0

  name                 = module.task_label.id
  assume_role_policy   = one(data.aws_iam_policy_document.ecs_task[*]["json"])
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = var.role_tags_enabled ? module.task_label.tags : null
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  for_each   = local.create_task_role ? local.task_policy_arns_map : {}
  policy_arn = each.value
  role       = one(aws_iam_role.ecs_task[*]["id"])
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
  assume_role_policy   = one(data.aws_iam_policy_document.ecs_service[*]["json"])
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = var.role_tags_enabled ? module.service_label.tags : null
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
  policy = one(data.aws_iam_policy_document.ecs_service_policy[*]["json"])
  role   = one(aws_iam_role.ecs_service[*]["id"])
}

data "aws_iam_policy_document" "ecs_ssm_exec" {
  count = local.create_task_role && var.exec_enabled ? 1 : 0

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
  count  = local.create_task_role && var.exec_enabled ? 1 : 0
  name   = module.task_label.id
  policy = one(data.aws_iam_policy_document.ecs_ssm_exec[*]["json"])
  role   = one(aws_iam_role.ecs_task[*]["id"])
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "ecs_task_exec" {
  count = local.create_exec_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_exec" {
  count                = local.create_exec_role ? 1 : 0
  name                 = module.exec_label.id
  assume_role_policy   = one(data.aws_iam_policy_document.ecs_task_exec[*]["json"])
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = var.role_tags_enabled ? module.exec_label.tags : null
}

data "aws_iam_policy_document" "ecs_exec" {
  count = local.create_exec_role ? 1 : 0

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
  for_each = local.create_exec_role ? toset(["true"]) : toset([])
  name     = module.exec_label.id
  policy   = one(data.aws_iam_policy_document.ecs_exec[*]["json"])
  role     = one(aws_iam_role.ecs_exec[*]["id"])
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  for_each   = local.create_exec_role ? local.task_exec_policy_arns_map : {}
  policy_arn = each.value
  role       = one(aws_iam_role.ecs_exec[*]["id"])
}

# IAM role that Amazon ECS uses to enable TLS on Service Connect
data "aws_iam_policy_document" "ecs_service_connect_tls" {
  count = local.create_service_connect_tls_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_connect_tls" {
  count                = local.create_service_connect_tls_role ? 1 : 0
  name                 = module.service_connect_label.id
  assume_role_policy   = one(data.aws_iam_policy_document.ecs_service_connect_tls[*]["json"])
  permissions_boundary = var.permissions_boundary == "" ? null : var.permissions_boundary
  tags                 = var.role_tags_enabled ? module.service_connect_label.tags : null
}

resource "aws_iam_role_policy_attachment" "ecs_service_connect_tls" {
  count      = local.create_service_connect_tls_role ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRolePolicyForServiceConnectTransportLayerSecurity"
  role       = one(aws_iam_role.ecs_service_connect_tls[*]["id"])
}

# Service
## Security Groups
resource "aws_security_group" "ecs_service" {
  count       = local.create_security_group ? 1 : 0
  vpc_id      = var.vpc_id
  name        = module.service_label.id
  description = var.security_group_description
  tags        = module.service_label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  count             = local.create_security_group && var.enable_all_egress_rule ? 1 : 0
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = one(aws_security_group.ecs_service[*]["id"])
}

resource "aws_security_group_rule" "allow_icmp_ingress" {
  count             = local.create_security_group && var.enable_icmp_rule ? 1 : 0
  description       = "Allow ping command from anywhere, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html#sg-rules-ping"
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = one(aws_security_group.ecs_service[*]["id"])
}

resource "aws_security_group_rule" "alb" {
  count                    = local.create_security_group && var.use_alb_security_group ? 1 : 0
  description              = "Allow inbound traffic from ALB"
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
  security_group_id        = one(aws_security_group.ecs_service[*]["id"])
}

resource "aws_security_group_rule" "nlb" {
  count             = local.create_security_group && var.use_nlb_cidr_blocks ? 1 : 0
  description       = "Allow inbound traffic from NLB"
  type              = "ingress"
  from_port         = var.nlb_container_port
  to_port           = var.nlb_container_port
  protocol          = "tcp"
  cidr_blocks       = var.nlb_cidr_blocks
  security_group_id = one(aws_security_group.ecs_service[*]["id"])
}

resource "aws_ecs_service" "ignore_changes_task_definition" {
  count                              = local.ecs_service_enabled && var.ignore_changes_task_definition && !var.ignore_changes_desired_count ? 1 : 0
  name                               = module.this.id
  task_definition                    = local.create_task_definition ? "${join("", aws_ecs_task_definition.default[*].family)}:${join("", aws_ecs_task_definition.default[*].revision)}" : var.task_definition[0]
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = length(var.capacity_provider_strategies) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.scheduling_strategy
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  iam_role                           = local.enable_ecs_service_role ? coalesce(var.service_role_arn, one(aws_iam_role.ecs_service[*]["arn"])) : null
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

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configurations
    content {
      enabled   = service_connect_configuration.value.enabled
      namespace = service_connect_configuration.value.namespace
      dynamic "log_configuration" {
        for_each = try(service_connect_configuration.value.log_configuration, null) == null ? [] : [service_connect_configuration.value.log_configuration]
        content {
          log_driver = log_configuration.value.log_driver
          options    = log_configuration.value.options
          dynamic "secret_option" {
            for_each = length(log_configuration.value.secret_option) == 0 ? [] : [log_configuration.value.secret_option]
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }
      dynamic "service" {
        for_each = length(service_connect_configuration.value.service) == 0 ? [] : service_connect_configuration.value.service
        content {
          discovery_name        = service.value.discovery_name
          ingress_port_override = service.value.ingress_port_override
          port_name             = service.value.port_name
          dynamic "client_alias" {
            for_each = service.value.client_alias
            content {
              dns_name = client_alias.value.dns_name
              port     = client_alias.value.port
            }
          }
          dynamic "timeout" {
            for_each = length(service.value.timeout) == 0 ? [] : service.value.timeout
            content {
              idle_timeout_seconds        = timeout.value.idle_timeout_seconds
              per_request_timeout_seconds = timeout.value.per_request_timeout_seconds
            }
          }
          dynamic "tls" {
            for_each = length(service.value.tls) == 0 ? [] : service.value.tls
            content {
              kms_key  = tls.value.kms_key
              role_arn = tls.value.role_arn != null ? tls.value.role_arn : one(aws_iam_role.ecs_service_connect_tls[*].arn)
              issuer_cert_authority {
                aws_pca_authority_arn = tls.value.issuer_cert_authority.aws_pca_authority_arn
              }
            }
          }
        }
      }
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
      security_groups  = compact(concat(var.security_group_ids, aws_security_group.ecs_service[*]["id"]))
      subnets          = var.subnet_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller_type == "ECS" ? ["true"] : []
    content {
      enable   = var.circuit_breaker_deployment_enabled
      rollback = var.circuit_breaker_rollback_enabled
    }
  }

  triggers = local.redeployment_trigger

  lifecycle {
    ignore_changes = [task_definition]
  }

  # Avoid race condition on destroy.
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
  depends_on = [aws_iam_role.ecs_service, aws_iam_role_policy.ecs_service]
}

resource "aws_ecs_service" "ignore_changes_task_definition_and_desired_count" {
  count                              = local.ecs_service_enabled && var.ignore_changes_task_definition && var.ignore_changes_desired_count ? 1 : 0
  name                               = module.this.id
  task_definition                    = local.create_task_definition ? "${join("", aws_ecs_task_definition.default[*].family)}:${join("", aws_ecs_task_definition.default[*].revision)}" : var.task_definition[0]
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = length(var.capacity_provider_strategies) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.scheduling_strategy
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  iam_role                           = local.enable_ecs_service_role ? coalesce(var.service_role_arn, one(aws_iam_role.ecs_service[*]["arn"])) : null
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

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configurations
    content {
      enabled   = service_connect_configuration.value.enabled
      namespace = service_connect_configuration.value.namespace
      dynamic "log_configuration" {
        for_each = try(service_connect_configuration.value.log_configuration, null) == null ? [] : [service_connect_configuration.value.log_configuration]
        content {
          log_driver = log_configuration.value.log_driver
          options    = log_configuration.value.options
          dynamic "secret_option" {
            for_each = length(log_configuration.value.secret_option) == 0 ? [] : [log_configuration.value.secret_option]
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }
      dynamic "service" {
        for_each = length(service_connect_configuration.value.service) == 0 ? [] : service_connect_configuration.value.service
        content {
          discovery_name        = service.value.discovery_name
          ingress_port_override = service.value.ingress_port_override
          port_name             = service.value.port_name
          dynamic "client_alias" {
            for_each = service.value.client_alias
            content {
              dns_name = client_alias.value.dns_name
              port     = client_alias.value.port
            }
          }
          dynamic "timeout" {
            for_each = length(service.value.timeout) == 0 ? [] : service.value.timeout
            content {
              idle_timeout_seconds        = timeout.value.idle_timeout_seconds
              per_request_timeout_seconds = timeout.value.per_request_timeout_seconds
            }
          }
          dynamic "tls" {
            for_each = length(service.value.tls) == 0 ? [] : service.value.tls
            content {
              kms_key  = tls.value.kms_key
              role_arn = tls.value.role_arn != null ? tls.value.role_arn : one(aws_iam_role.ecs_service_connect_tls[*].arn)
              issuer_cert_authority {
                aws_pca_authority_arn = tls.value.issuer_cert_authority.aws_pca_authority_arn
              }
            }
          }
        }
      }
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
      security_groups  = compact(concat(var.security_group_ids, aws_security_group.ecs_service[*]["id"]))
      subnets          = var.subnet_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller_type == "ECS" ? ["true"] : []
    content {
      enable   = var.circuit_breaker_deployment_enabled
      rollback = var.circuit_breaker_rollback_enabled
    }
  }

  triggers = local.redeployment_trigger

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  # Avoid race condition on destroy.
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
  depends_on = [aws_iam_role.ecs_service, aws_iam_role_policy.ecs_service]
}

resource "aws_ecs_service" "ignore_changes_desired_count" {
  count                              = local.ecs_service_enabled && !var.ignore_changes_task_definition && var.ignore_changes_desired_count ? 1 : 0
  name                               = module.this.id
  task_definition                    = local.create_task_definition ? "${join("", aws_ecs_task_definition.default[*].family)}:${join("", aws_ecs_task_definition.default[*].revision)}" : var.task_definition[0]
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = length(var.capacity_provider_strategies) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.scheduling_strategy
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  iam_role                           = local.enable_ecs_service_role ? coalesce(var.service_role_arn, one(aws_iam_role.ecs_service[*]["arn"])) : null
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

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configurations
    content {
      enabled   = service_connect_configuration.value.enabled
      namespace = service_connect_configuration.value.namespace
      dynamic "log_configuration" {
        for_each = try(service_connect_configuration.value.log_configuration, null) == null ? [] : [service_connect_configuration.value.log_configuration]
        content {
          log_driver = log_configuration.value.log_driver
          options    = log_configuration.value.options
          dynamic "secret_option" {
            for_each = length(log_configuration.value.secret_option) == 0 ? [] : [log_configuration.value.secret_option]
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }
      dynamic "service" {
        for_each = length(service_connect_configuration.value.service) == 0 ? [] : service_connect_configuration.value.service
        content {
          discovery_name        = service.value.discovery_name
          ingress_port_override = service.value.ingress_port_override
          port_name             = service.value.port_name
          dynamic "client_alias" {
            for_each = service.value.client_alias
            content {
              dns_name = client_alias.value.dns_name
              port     = client_alias.value.port
            }
          }
          dynamic "timeout" {
            for_each = length(service.value.timeout) == 0 ? [] : service.value.timeout
            content {
              idle_timeout_seconds        = timeout.value.idle_timeout_seconds
              per_request_timeout_seconds = timeout.value.per_request_timeout_seconds
            }
          }
          dynamic "tls" {
            for_each = length(service.value.tls) == 0 ? [] : service.value.tls
            content {
              kms_key  = tls.value.kms_key
              role_arn = tls.value.role_arn != null ? tls.value.role_arn : one(aws_iam_role.ecs_service_connect_tls[*].arn)
              issuer_cert_authority {
                aws_pca_authority_arn = tls.value.issuer_cert_authority.aws_pca_authority_arn
              }
            }
          }
        }
      }
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
      security_groups  = compact(concat(var.security_group_ids, aws_security_group.ecs_service[*]["id"]))
      subnets          = var.subnet_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller_type == "ECS" ? ["true"] : []
    content {
      enable   = var.circuit_breaker_deployment_enabled
      rollback = var.circuit_breaker_rollback_enabled
    }
  }

  triggers = local.redeployment_trigger

  lifecycle {
    ignore_changes = [desired_count]
  }

  # Avoid race condition on destroy.
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
  depends_on = [aws_iam_role.ecs_service, aws_iam_role_policy.ecs_service]
}

resource "aws_ecs_service" "default" {
  count                              = local.ecs_service_enabled && !var.ignore_changes_task_definition && !var.ignore_changes_desired_count ? 1 : 0
  name                               = module.this.id
  task_definition                    = local.create_task_definition ? "${join("", aws_ecs_task_definition.default[*].family)}:${join("", aws_ecs_task_definition.default[*].revision)}" : var.task_definition[0]
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  launch_type                        = length(var.capacity_provider_strategies) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  scheduling_strategy                = var.launch_type == "FARGATE" ? "REPLICA" : var.scheduling_strategy
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  iam_role                           = local.enable_ecs_service_role ? coalesce(var.service_role_arn, one(aws_iam_role.ecs_service[*]["arn"])) : null
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

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configurations
    content {
      enabled   = service_connect_configuration.value.enabled
      namespace = service_connect_configuration.value.namespace
      dynamic "log_configuration" {
        for_each = try(service_connect_configuration.value.log_configuration, null) == null ? [] : [service_connect_configuration.value.log_configuration]
        content {
          log_driver = log_configuration.value.log_driver
          options    = log_configuration.value.options
          dynamic "secret_option" {
            for_each = length(log_configuration.value.secret_option) == 0 ? [] : [log_configuration.value.secret_option]
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }
      dynamic "service" {
        for_each = length(service_connect_configuration.value.service) == 0 ? [] : service_connect_configuration.value.service
        content {
          discovery_name        = service.value.discovery_name
          ingress_port_override = service.value.ingress_port_override
          port_name             = service.value.port_name
          dynamic "client_alias" {
            for_each = service.value.client_alias
            content {
              dns_name = client_alias.value.dns_name
              port     = client_alias.value.port
            }
          }
          dynamic "timeout" {
            for_each = length(service.value.timeout) == 0 ? [] : service.value.timeout
            content {
              idle_timeout_seconds        = timeout.value.idle_timeout_seconds
              per_request_timeout_seconds = timeout.value.per_request_timeout_seconds
            }
          }
          dynamic "tls" {
            for_each = length(service.value.tls) == 0 ? [] : service.value.tls
            content {
              kms_key  = tls.value.kms_key
              role_arn = tls.value.role_arn != null ? tls.value.role_arn : one(aws_iam_role.ecs_service_connect_tls[*].arn)
              issuer_cert_authority {
                aws_pca_authority_arn = tls.value.issuer_cert_authority.aws_pca_authority_arn
              }
            }
          }
        }
      }
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
      security_groups  = compact(concat(var.security_group_ids, aws_security_group.ecs_service[*]["id"]))
      subnets          = var.subnet_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller_type == "ECS" ? ["true"] : []
    content {
      enable   = var.circuit_breaker_deployment_enabled
      rollback = var.circuit_breaker_rollback_enabled
    }
  }

  triggers = local.redeployment_trigger

  # Avoid race condition on destroy.
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
  depends_on = [aws_iam_role.ecs_service, aws_iam_role_policy.ecs_service]

}
