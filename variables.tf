variable "name" {
  description = "The name of the app to be used in labels."
  default     = "app"
}

variable "namespace" {
  description = "The namespace to be used in labels."
  default     = "global"
}

variable "delimiter" {
  description = "The delimiter to be used in labels."
  default     = "-"
}

variable "stage" {
  description = "Stage to be used in labels."
  default     = "default"
}

variable "attributes" {
  type    = "list"
  default = []
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "vpc_id" {
  description = "The VPC id where resources are created."
}

variable "alb_target_group_arn" {
  description = "The ALB target group arn for the ECS service."
}

variable "ecs_cluster_arn" {
  description = "The arn of the ECS cluster where service will be provisioned."
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository to store images."
}

variable "container_definition_json" {
  description = "The JSON of the task container definition."
}

variable "private_subnet_ids" {
  description = "Private subnet ids."
  type        = "list"
}

variable "security_group_ids" {
  description = "Security group IDs to allow in Service network_configuration."
  type        = "list"
}

variable "family" {
  description = "The name used for multiple versions of a task definition."
  default     = "web"
}

variable "launch_type" {
  description = "The launch type on which to run your service. Valid values are EC2 and FARGATE."
  default     = "FARGATE"
}

variable "network_mode" {
  description = "The network mode to use for the task. This is required to be awsvpc for FARGATE launch_type."
  default     = "awsvpc"
}

variable "task_cpu" {
  description = "The number of CPU units used by the task. If using Fargate launch type task_cpu must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)."
  default     = 256
}

variable "task_memory" {
  description = "The amount of memory (in MiB) used by the task. If using Fargate launch type task_memory must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)."
  default     = 512
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  default     = 1
}

variable "deployment_maximum_percent" {
  description = "The upper limit of the number of tasks (as a percentage of desired_count) that can be running in a service during a deployment."
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit (as a percentage of desired_count) of the number of tasks that must remain running and healthy in a service during a deployment."
  default     = 100
}
