# TODO: (output) security group IDs

output "service_name" {
  description = "ECS Service name."
  value = "${aws_ecs_service.default.name}"
}
