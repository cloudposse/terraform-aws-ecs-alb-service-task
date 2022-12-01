output "ecs_exec_role_policy_id" {
  description = "The ECS service role policy ID, in the form of `role_name:role_policy_name`"
  value = join("", [
    for k, v in aws_iam_role_policy.ecs_exec : v.id
  ])
}

output "ecs_exec_role_policy_name" {
  description = "ECS service role name"
  value = join("", [
    for k, v in aws_iam_role_policy.ecs_exec : v.name
  ])
}

output "service_name" {
  description = "ECS Service name"
  value       = try(aws_ecs_service.default[0].name, aws_ecs_service.ignore_changes_task_definition[0].name, aws_ecs_service.ignore_changes_desired_count[0].name, aws_ecs_service.ignore_changes_task_definition_and_desired_count[0].name, "")
}

output "service_arn" {
  description = "ECS Service ARN"
  value       = try(aws_ecs_service.default[0].id, aws_ecs_service.ignore_changes_task_definition[0].id, aws_ecs_service.ignore_changes_desired_count[0].id, aws_ecs_service.ignore_changes_task_definition_and_desired_count[0].id, "")
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
  value       = length(local.task_exec_role_arn) > 0 ? local.task_exec_role_arn : join("", aws_iam_role.ecs_exec.*.arn)
}

output "task_exec_role_id" {
  description = "ECS Task exec role id"
  value       = join("", aws_iam_role.ecs_exec.*.unique_id)
}

output "task_role_name" {
  description = "ECS Task role name"
  value       = join("", aws_iam_role.ecs_task.*.name)
}

output "task_role_arn" {
  description = "ECS Task role ARN"
  value       = length(local.task_role_arn) > 0 ? local.task_role_arn : join("", aws_iam_role.ecs_task.*.arn)
}

output "task_role_id" {
  description = "ECS Task role id"
  value       = join("", aws_iam_role.ecs_task.*.unique_id)
}

output "service_security_group_id" {
  description = "Security Group ID of the ECS task"
  value       = join("", aws_security_group.ecs_service.*.id)
}

output "task_definition_family" {
  description = "ECS task definition family"
  value       = join("", aws_ecs_task_definition.default.*.family)
}

output "task_definition_revision" {
  description = "ECS task definition revision"
  value       = join("", aws_ecs_task_definition.default.*.revision)
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = join("", aws_ecs_task_definition.default.*.arn)
}
