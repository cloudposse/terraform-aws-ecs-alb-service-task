output "ecs_exec_role_policy_id" {
  description = "The ECS service role policy ID, in the form of `role_name:role_policy_name`"
  value       = join("", aws_iam_role_policy.ecs_exec.*.id)
}

output "ecs_exec_role_policy_name" {
  description = "ECS service role name"
  value       = join("", aws_iam_role_policy.ecs_exec.*.name)
}

output "service_name" {
  description = "ECS Service name"
  value = try(
    aws_ecs_service.default[0].name,
    aws_ecs_service.ignore_changes_task_definition[0].name,
    aws_ecs_service.ignore_changes_desired_count[0].name,
    aws_ecs_service.ignore_changes_task_definition_and_desired_count[0].name,
    ""
  )
}

output "service_arn" {
  description = "ECS Service ARN"
  value = try(
    aws_ecs_service.default[0].id,
    aws_ecs_service.ignore_changes_task_definition[0].id,
    aws_ecs_service.ignore_changes_desired_count[0].id,
    aws_ecs_service.ignore_changes_task_definition_and_desired_count[0].id,
    ""
  )
}

output "service_role_arn" {
  description = "ECS Service role ARN"
  value       = join("", aws_iam_role.ecs_service.*.arn)
}

output "task_exec_role_name" {
  description = "ECS Task role name"
  value       = join("", aws_iam_role.ecs_exec.*.name)
}

output "task_exec_role_arn" {
  description = "ECS Task exec role ARN"
  value       = length(var.task_exec_role_arn) > 0 ? var.task_exec_role_arn : join("", aws_iam_role.ecs_exec.*.arn)
}

output "task_role_name" {
  description = "ECS Task role name"
  value       = join("", aws_iam_role.ecs_task.*.name)
}

output "task_role_arn" {
  description = "ECS Task role ARN"
  value       = length(var.task_role_arn) > 0 ? var.task_role_arn : join("", aws_iam_role.ecs_task.*.arn)
}

output "task_role_id" {
  description = "ECS Task role id"
  value       = join("", aws_iam_role.ecs_task.*.unique_id)
}

output "security_group_id" {
  value       = module.security_group.id
  description = "Security Group ID of the ECS task"
}

output "security_group_arn" {
  value       = module.security_group.arn
  description = "Security Group ARN of the ECS task"
}

output "security_group_name" {
  value       = module.security_group.name
  description = "Security Group name of the ECS task"
}

output "task_definition_family" {
  description = "ECS task definition family"
  value       = join("", aws_ecs_task_definition.default.*.family)
}

output "task_definition_revision" {
  description = "ECS task definition revision"
  value       = join("", aws_ecs_task_definition.default.*.revision)
}

output "aws_ecs_service_obj" {
  description = "Parameters to create the service"
  value = {
    name                               = module.this.id
    task_definition                    = local.ecs_service_task_definition
    desired_count                      = var.desired_count
    deployment_maximum_percent         = var.deployment_maximum_percent
    deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
    health_check_grace_period_seconds  = var.health_check_grace_period_seconds
    launch_type                        = local.ecs_service_launch_type
    platform_version                   = local.ecs_service_platform_version
    scheduling_strategy                = local.ecs_service_scheduling_strategy
    enable_ecs_managed_tags            = var.enable_ecs_managed_tags
    iam_role                           = local.ecs_service_iam_role
    wait_for_steady_state              = var.wait_for_steady_state
    force_new_deployment               = var.force_new_deployment
    enable_execute_command             = var.exec_enabled
    cluster                            = var.ecs_cluster_arn
    propagate_tags                     = var.propagate_tags
    tags                               = var.use_old_arn ? null : module.this.tags
    deployment_controller_type         = var.deployment_controller_type

    capacity_provider_strategies  = var.capacity_provider_strategies
    service_registries            = var.service_registries
    ordered_placement_strategy    = var.ordered_placement_strategy
    service_placement_constraints = var.service_placement_constraints
    ecs_load_balancers            = var.ecs_load_balancers

    network_mode     = var.network_mode
    security_groups  = compact(concat(module.security_group.*.id, var.security_groups))
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }
}
