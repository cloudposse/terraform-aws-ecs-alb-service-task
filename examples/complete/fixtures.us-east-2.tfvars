region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "ecs-alb-service-task"

vpc_cidr_block = "172.16.0.0/16"

ecs_launch_type = "FARGATE"

network_mode = "awsvpc"

ignore_changes_task_definition = true

assign_public_ip = false

propagate_tags = "TASK_DEFINITION"

deployment_minimum_healthy_percent = 100

deployment_maximum_percent = 200

deployment_controller_type = "ECS"

desired_count = 1

task_memory = 512

task_cpu = 256

container_name = "geodesic"

container_image = "cloudposse/geodesic"

container_memory = 256

container_memory_reservation = 128

container_cpu = 256

container_essential = true

container_readonly_root_filesystem = false

container_environment = [
  {
    name  = "string_var"
    value = "I am a string"
  },
  {
    name  = "true_boolean_var"
    value = true
  },
  {
    name  = "false_boolean_var"
    value = false
  },
  {
    name  = "integer_var"
    value = 42
  }
]

container_port_mappings = [
  {
    containerPort = 80
    hostPort      = 80
    protocol      = "tcp"
  },
  {
    containerPort = 443
    hostPort      = 443
    protocol      = "udp"
  }
]

force_new_deployment = true
redeploy_on_apply    = true

service_autoscaling_enabled          = true
service_autoscaling_minimum_capacity = 1
service_autoscaling_maximum_capacity = 3
service_autoscaling_target_tracking_policies = {
  cpu = {
    predefined_metric_type = "ECSServiceAverageCPUUtilization"
    target_value           = 50
    scale_out_cooldown     = 60
    scale_in_cooldown      = 60
  },
  memory = {
    predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    target_value           = 80
  }
}
