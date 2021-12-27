output "public_subnet_cidrs" {
  value       = module.subnets.public_subnet_cidrs
  description = "Public subnet CIDRs"
}

output "private_subnet_cidrs" {
  value       = module.subnets.private_subnet_cidrs
  description = "Private subnet CIDRs"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC ID"
}

output "container_definition_json" {
  value       = module.container_definition.json_map_encoded_list
  description = "JSON encoded list of container definitions for use with other terraform resources such as aws_ecs_task_definition"
}

output "container_definition_json_map" {
  value       = module.container_definition.json_map_encoded
  description = "JSON encoded container definitions for use with other terraform resources such as aws_ecs_task_definition"
}

output "ecs_cluster_id" {
  value       = aws_ecs_cluster.default.id
  description = "ECS cluster ID"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.default.arn
  description = "ECS cluster ARN"
}

output "ecs_exec_role_policy_id" {
  description = "The ECS service role policy ID, in the form of `role_name:role_policy_name`"
  value       = module.ecs_alb_service_task.ecs_exec_role_policy_id
}

output "ecs_exec_role_policy_name" {
  description = "ECS service role name"
  value       = module.ecs_alb_service_task.ecs_exec_role_policy_name
}

output "service_name" {
  description = "ECS Service name"
  value       = module.ecs_alb_service_task.service_name
}

output "service_role_arn" {
  description = "ECS Service role ARN"
  value       = module.ecs_alb_service_task.service_role_arn
}

output "task_exec_role_name" {
  description = "ECS Task role name"
  value       = module.ecs_alb_service_task.task_exec_role_name
}

output "task_exec_role_arn" {
  description = "ECS Task exec role ARN"
  value       = module.ecs_alb_service_task.task_exec_role_arn
}

output "task_role_name" {
  description = "ECS Task role name"
  value       = module.ecs_alb_service_task.task_role_name
}

output "task_role_arn" {
  description = "ECS Task role ARN"
  value       = module.ecs_alb_service_task.task_role_arn
}

output "task_role_id" {
  description = "ECS Task role id"
  value       = module.ecs_alb_service_task.task_role_id
}

output "service_security_group_id" {
  description = "Security Group ID of the ECS task"
  value       = module.ecs_alb_service_task.service_security_group_id
}

output "task_definition_family" {
  description = "ECS task definition family"
  value       = module.ecs_alb_service_task.task_definition_family
}

output "task_definition_revision" {
  description = "ECS task definition revision"
  value       = module.ecs_alb_service_task.task_definition_revision
}
