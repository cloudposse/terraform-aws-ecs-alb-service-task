variable "app_name" {
  description = "The name of the app."
}

variable "vpc_id" {
  description = "The VPC id where resources are created."
}

variable "alb_arn" {
  description = "The ALB arn where listener and target group will be created."
}

variable "stage" {
  description = "Stage of the resources."
}

variable "private_subnet_ids" {
  description = "Private subnet ids."
  type        = "list"
}

variable "security_group_ids" {
  description = "Security group IDs to allow in Service network_configuration."
  type        = "list"
}

#variable "acm_arn" {
#  description = "The arn of the ACM certificate."
#}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  default     = 1
}

variable "launch_type" {
  description = "The launch type on which to run your service. Valid values are EC2 and FARGATE."
}

variable "task_cpu" {
  description = "The number of CPU units used by the task. If using Fargate launch type task_cpu must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)."
  default     = 256
}

variable "task_memory" {
  description = "The amount of memory (in MiB) used by the task. If using Fargate launch type task_memory must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)."
  default     = 512
}
