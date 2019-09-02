variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'cluster'"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where resources are created"
}

variable "alb_target_group_arn" {
  type        = string
  description = "The ALB target group ARN for the ECS service"
}

variable "alb_security_group" {
  type        = string
  description = "Security group of the ALB"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ARN of the ECS cluster where service will be provisioned"
}

variable "container_definition_json" {
  type        = string
  description = "The JSON of the task container definition"
}

variable "container_name" {
  type        = string
  description = "The name of the container in task definition to associate with the load balancer"
}

variable "container_port" {
  description = "The port on the container to associate with the load balancer"
  default     = 80
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to allow in Service `network_configuration`"
  type        = list(string)
}

variable "launch_type" {
  type        = string
  description = "The launch type on which to run your service. Valid values are `EC2` and `FARGATE`"
  default     = "FARGATE"
}

variable "network_mode" {
  type        = string
  description = "The network mode to use for the task. This is required to be awsvpc for `FARGATE` `launch_type`"
  default     = "awsvpc"
}

variable "task_cpu" {
  description = "The number of CPU units used by the task. If using `FARGATE` launch type `task_cpu` must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = 256
}

variable "task_memory" {
  description = "The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = 512
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running"
  default     = 1
}

variable "deployment_controller_type" {
  description = "Type of deployment controller. Valid values: `CODE_DEPLOY`, `ECS`."
  default     = "ECS"
}

variable "deployment_maximum_percent" {
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
  default     = 100
}

variable "health_check_grace_period_seconds" {
  type        = string
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers"
  default     = 0
}

variable "volumes" {
  type        = list(string)
  description = "Task volume definitions as list of maps"
  default     = []
}

variable "ignore_changes_task_definition" {
  type        = string
  description = "Whether to ignore changes in container definition and task definition in the ECS service"
  default     = "true"
}

variable "assign_public_ip" {
  type        = string
  default     = "false"
  description = "Assign a public IP address to the ENI (Fargate launch type only). Valid values are true or false. Default false."
}

