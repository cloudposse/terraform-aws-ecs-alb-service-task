output "service_name" {
  description = "ECS Service name"
  value       = module.ecs_alb_service_task.service_name
}

output "alb_arn" {
  description = "ARN of the ALB fronting the blue/green example"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB fronting the blue/green example"
  value       = module.alb.alb_dns_name
}

output "blue_green_production_target_group_arn" {
  description = "ARN of the production (blue) target group"
  value       = module.alb.default_target_group_arn
}

output "blue_green_alternate_target_group_arn" {
  description = "ARN of the alternate (green) target group used for blue/green deployments"
  value       = one(aws_lb_target_group.alternate[*].arn)
}

output "blue_green_production_target_group_port" {
  description = "Port of the production (blue) target group"
  value       = local.enabled ? var.blue_green_container_port : null
}

output "blue_green_alternate_target_group_port" {
  description = "Port of the alternate (green) target group"
  value       = one(aws_lb_target_group.alternate[*].port)
}

output "blue_green_production_listener_rule_arn" {
  description = "ARN of the production listener rule that forwards to both target groups"
  value       = one(aws_lb_listener_rule.blue_green[*].arn)
}

output "blue_green_test_listener_rule_arn" {
  description = "ARN of the test listener rule that routes test traffic to the green target group"
  value       = one(aws_lb_listener_rule.blue_green_test[*].arn)
}
