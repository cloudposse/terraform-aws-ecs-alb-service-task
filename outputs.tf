output "service_name" {
  description = "ECS Service name"
  value       = "${aws_ecs_service.default.name}"
}

output "service_role_arn" {
  description = "ECS Service role ARN"
  value       = "${aws_iam_role.ecs_service.arn}"
}

output "task_role_arn" {
  description = "ECS Task role ARN"
  value       = "${aws_iam_role.ecs_task.arn}"
}
