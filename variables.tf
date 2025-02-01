variable "vpc_id" {
  type        = string
  description = "The VPC ID where resources are created"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ARN of the ECS cluster where service will be provisioned"
}

variable "ecs_load_balancers" {
  type = list(object({
    container_name   = string
    container_port   = number
    elb_name         = optional(string)
    target_group_arn = string
  }))
  description = "A list of load balancer config objects for the ECS service; see [ecs_service#load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#load_balancer) docs"
  default     = []
}

variable "container_definition_json" {
  type        = string
  description = <<-EOT
    A string containing a JSON-encoded array of container definitions
    (`"[{ "name": "container1", ... }, { "name": "container2", ... }]"`).
    See [API_ContainerDefinition](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html),
    [cloudposse/terraform-aws-ecs-container-definition](https://github.com/cloudposse/terraform-aws-ecs-container-definition), or
    [ecs_task_definition#container_definitions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#container_definitions)
    EOT
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs used in Service `network_configuration` if `var.network_mode = \"awsvpc\"`"
  default     = null
}

variable "security_group_enabled" {
  type        = bool
  description = "Whether to create a security group for the service."
  default     = true
}

variable "security_group_description" {
  type        = string
  default     = "Allow ALL egress from ECS service"
  description = <<-EOT
    The description to assign to the service security group.
    Warning: Changing the description causes the security group to be replaced.
    EOT
}

variable "enable_all_egress_rule" {
  type        = bool
  description = "A flag to enable/disable adding the all ports egress rule to the service security group"
  default     = true
}

variable "enable_icmp_rule" {
  type        = bool
  description = "Specifies whether to enable ICMP on the service security group"
  default     = false
}

variable "use_alb_security_group" {
  type        = bool
  description = "A flag to enable/disable allowing traffic from the ALB security group to the service security group"
  default     = false
}

variable "alb_security_group" {
  type        = string
  description = "Security group of the ALB"
  default     = ""
}

variable "container_port" {
  type        = number
  description = "The port on the container to allow traffic from the ALB security group"
  default     = 80
}

variable "use_nlb_cidr_blocks" {
  type        = bool
  description = "A flag to enable/disable adding the NLB ingress rule to the service security group"
  default     = false
}

variable "nlb_container_port" {
  type        = number
  description = "The port on the container to allow traffic from the NLB"
  default     = 80
}

variable "nlb_cidr_blocks" {
  type        = list(string)
  description = "A list of CIDR blocks to add to the ingress rule for the NLB container port"
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs to allow in Service `network_configuration` if `var.network_mode = \"awsvpc\"`"
  type        = list(string)
  default     = []
}

variable "launch_type" {
  type        = string
  description = "The launch type on which to run your service. Valid values are `EC2` and `FARGATE`"
  default     = "FARGATE"
}

variable "platform_version" {
  type        = string
  default     = "LATEST"
  description = <<-EOT
    The platform version on which to run your service. Only applicable for `launch_type` set to `FARGATE`.
    More information about Fargate platform versions can be found in the AWS ECS User Guide.
    EOT
}

variable "scheduling_strategy" {
  type        = string
  default     = "REPLICA"
  description = <<-EOT
    The scheduling strategy to use for the service. The valid values are `REPLICA` and `DAEMON`.
    Note that Fargate tasks do not support the DAEMON scheduling strategy.
    EOT
}

variable "ordered_placement_strategy" {
  type = list(object({
    type  = string
    field = string
  }))
  default     = []
  description = <<-EOT
    Service level strategy rules that are taken into consideration during task placement.
    List from top to bottom in order of precedence. The maximum number of ordered_placement_strategy blocks is 5.
    See [`ordered_placement_strategy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#ordered_placement_strategy)
    EOT
}

variable "task_placement_constraints" {
  type = list(object({
    type       = string
    expression = string
  }))
  default     = []
  description = <<-EOT
    A set of placement constraints rules that are taken into consideration during task placement.
    Maximum number of placement_constraints is 10. See [`placement_constraints`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#placement-constraints-arguments)
    EOT
}

variable "service_placement_constraints" {
  type = list(object({
    type       = string
    expression = string
  }))
  description = "The rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. See [`placement_constraints`](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#placement_constraints-1) docs"
  default     = []
}

variable "network_mode" {
  type        = string
  description = "The network mode to use for the task. This is required to be `awsvpc` for `FARGATE` `launch_type` or `null` for `EC2` `launch_type`"
  default     = "awsvpc"
}

variable "task_cpu" {
  type        = number
  description = "The number of CPU units used by the task. If using `FARGATE` launch type `task_cpu` must match [supported memory values](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match [supported cpu value](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = 512
}

variable "task_exec_role_arn" {
  type        = any
  description = <<-EOT
    A `list(string)` of zero or one ARNs of IAM roles that allows the
    ECS/Fargate agent to make calls to the ECS API on your behalf.
    If the list is empty, a role will be created for you.
    DEPRECATED: you can also pass a `string` with the ARN, but that
    string must be known a "plan" time.
    EOT
  default     = []
}

variable "task_exec_policy_arns" {
  type        = list(string)
  description = <<-EOT
    A list of IAM Policy ARNs to attach to the generated task execution role.
    Changes to the list will have ripple effects, so use `task_exec_policy_arns_map` if possible.
    EOT
  default     = []
}

variable "task_exec_policy_arns_map" {
  type        = map(string)
  description = <<-EOT
    A map of name to IAM Policy ARNs to attach to the generated task execution role.
    The names are arbitrary, but must be known at plan time. The purpose of the name
    is so that changes to one ARN do not cause a ripple effect on the other ARNs.
    If you cannot provide unique names known at plan time, use `task_exec_policy_arns` instead.
    EOT
  default     = {}
}

variable "task_role_arn" {
  type        = any
  description = <<-EOT
    A `list(string)` of zero or one ARNs of IAM roles that allows
    your Amazon ECS container task to make calls to other AWS services.
    If the list is empty, a role will be created for you.
    DEPRECATED: you can also pass a `string` with the ARN, but that
    string must be known a "plan" time.
    EOT
  default     = []
}

variable "task_policy_arns" {
  type        = list(string)
  description = <<-EOT
    A list of IAM Policy ARNs to attach to the generated task role.
    Changes to the list will have ripple effects, so use `task_policy_arns_map` if possible.
    EOT

  default = []
}

variable "task_policy_arns_map" {
  type        = map(string)
  description = <<-EOT
    A map of name to IAM Policy ARNs to attach to the generated task role.
    The names are arbitrary, but must be known at plan time. The purpose of the name
    is so that changes to one ARN do not cause a ripple effect on the other ARNs.
    If you cannot provide unique names known at plan time, use `task_policy_arns` instead.
    EOT
  default     = {}
}

variable "service_role_arn" {
  type        = string
  description = "ARN of the IAM role that allows Amazon ECS to make calls to your load balancer on your behalf. This parameter is required if you are using a load balancer with your service, but only if your task definition does not use the awsvpc network mode. If using awsvpc network mode, do not specify this role. If your account has already created the Amazon ECS service-linked role, that role is used by default for your service unless you specify a role here."
  default     = null
}

variable "desired_count" {
  type        = number
  description = "The number of instances of the task definition to place and keep running"
  default     = 1
}

variable "deployment_controller_type" {
  type        = string
  description = "Type of deployment controller. Valid values are `CODE_DEPLOY` and `ECS`"
  default     = "ECS"
}

variable "deployment_maximum_percent" {
  type        = number
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
  default     = 100
}

variable "availability_zone_rebalancing" {
  type        = string
  description = "ECS automatically redistributes tasks within a service across Availability Zones (AZs) to mitigate the risk of impaired application availability due to underlying infrastructure failures and task lifecycle activities. The valid values are `ENABLED` and `DISABLED`."
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.availability_zone_rebalancing)
    error_message = "The valid values are `ENABLED` and `DISABLED`."
  }
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers"
  default     = 0
}

variable "runtime_platform" {
  type        = list(map(string))
  description = <<-EOT
    Zero or one runtime platform configurations that containers in your task may use.
    Map of strings with optional keys `operating_system_family` and `cpu_architecture`.
    See `runtime_platform` docs https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#runtime_platform
    EOT
  default     = []
}

variable "efs_volumes" {
  type = list(object({
    host_path = string
    name      = string
    efs_volume_configuration = list(object({
      file_system_id          = string
      root_directory          = string
      transit_encryption      = string
      transit_encryption_port = string
      authorization_config = list(object({
        access_point_id = string
        iam             = string
      }))
    }))
  }))

  description = "Task EFS volume definitions as list of configuration objects. You can define multiple EFS volumes on the same task definition, but a single volume can only have one `efs_volume_configuration`."
  default     = []
}

variable "bind_mount_volumes" {
  type = list(any)
  #  host_path = optional(string)
  #  name      = string
  description = "Task bind mount volume definitions as list of configuration objects. You can define multiple bind mount volumes on the same task definition. Requires `name` and optionally `host_path`"
  default     = []
}

variable "docker_volumes" {
  type = list(object({
    host_path = string
    name      = string
    docker_volume_configuration = list(object({
      autoprovision = bool
      driver        = string
      driver_opts   = map(string)
      labels        = map(string)
      scope         = string
    }))
  }))

  description = "Task docker volume definitions as list of configuration objects. You can define multiple Docker volumes on the same task definition, but a single volume can only have one `docker_volume_configuration`."
  default     = []
}

variable "fsx_volumes" {
  type = list(object({
    host_path = string
    name      = string
    fsx_windows_file_server_volume_configuration = list(object({
      file_system_id = string
      root_directory = string
      authorization_config = list(object({
        credentials_parameter = string
        domain                = string
      }))
    }))
  }))

  description = "Task FSx volume definitions as list of configuration objects. You can define multiple FSx volumes on the same task definition, but a single volume can only have one `fsx_windows_file_server_volume_configuration`."
  default     = []
}

variable "proxy_configuration" {
  type = object({
    type           = string
    container_name = string
    properties     = map(string)
  })
  description = "The proxy configuration details for the App Mesh proxy. See `proxy_configuration` docs https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#proxy-configuration-arguments"
  default     = null
}

variable "ignore_changes_load_balancer" {
  type        = bool
  description = "Whether to ignore changes for Load balancer in the ECS service (useful when using CodeDeploy Blue/Green deployments to avoid drifts)"
  default     = false
}

variable "ignore_changes_task_definition" {
  type        = bool
  description = "Whether to ignore changes in container definition and task definition in the ECS service"
  default     = true
}

variable "ignore_changes_desired_count" {
  type        = bool
  description = "Whether to ignore changes for desired count in the ECS service"
  default     = false
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign a public IP address to the ENI (Fargate launch type only). Valid values are `true` or `false`. Default `false`"
  default     = false
}

variable "propagate_tags" {
  type        = string
  description = "Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION"
  default     = null
}

variable "enable_ecs_managed_tags" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS managed tags for the tasks within the service"
  default     = false
}

variable "capacity_provider_strategies" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  description = "The capacity provider strategies to use for the service. See `capacity_provider_strategy` configuration block: https://www.terraform.io/docs/providers/aws/r/ecs_service.html#capacity_provider_strategy"
  default     = []
}

variable "service_registries" {
  type        = list(any)
  description = <<-EOT
    Zero or one service discovery registries for the service.
    The currently supported service registry is Amazon Route 53 Auto Naming Service - `aws_service_discovery_service`;
    see `service_registries` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1"
    Service registry is object with required key `registry_arn = string` and optional keys
      `port           = number`
      `container_name = string`
      `container_port = number`
    EOT
  default     = []
}

variable "service_connect_configurations" {
  type = list(object({
    enabled   = bool
    namespace = optional(string, null)
    log_configuration = optional(object({
      log_driver = string
      options    = optional(map(string), null)
      secret_option = optional(list(object({
        name       = string
        value_from = string
      })), [])
    }), null)
    service = optional(list(object({
      client_alias = list(object({
        dns_name = string
        port     = number
      }))
      timeout = optional(list(object({
        idle_timeout_seconds        = optional(number, null)
        per_request_timeout_seconds = optional(number, null)
      })), [])
      tls = optional(list(object({
        kms_key  = optional(string, null)
        role_arn = optional(string, null)
        issuer_cert_authority = object({
          aws_pca_authority_arn = string
        })
      })), [])
      discovery_name        = optional(string, null)
      ingress_port_override = optional(number, null)
      port_name             = string
    })), [])
  }))
  description = <<-EOT
    The list of Service Connect configurations.
    See `service_connect_configuration` docs https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#service_connect_configuration
    EOT
  default     = []
}

variable "permissions_boundary" {
  type        = string
  description = "A permissions boundary ARN to apply to the 3 roles that are created."
  default     = ""
}

variable "use_old_arn" {
  type        = bool
  description = "A flag to enable/disable tagging the ecs resources that require the new arn format"
  default     = false
}

variable "wait_for_steady_state" {
  type        = bool
  description = "If true, it will wait for the service to reach a steady state (like aws ecs wait services-stable) before continuing"
  default     = false
}

variable "task_definition" {
  type        = any
  description = <<-EOT
    A `list(string)` of zero or one ARNs of task definitions, to reuse
    reuse an existing task definition family and revision for the ecs
    service instead of creating one
    DEPRECATED: you can also pass a `string` with the ARN, but that
    string must be known a "plan" time.
    EOT
  default     = []
}

variable "force_new_deployment" {
  type        = bool
  description = "Enable to force a new task deployment of the service."
  default     = false
}

variable "redeploy_on_apply" {
  type        = bool
  description = "Updates the service to the latest task definition on each apply"
  default     = false
}

variable "exec_enabled" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service"
  default     = false
}

variable "circuit_breaker_deployment_enabled" {
  type        = bool
  description = "If `true`, enable the deployment circuit breaker logic for the service. If using `CODE_DEPLOY` for `deployment_controller_type`, this value will be ignored"
  default     = false
}

variable "circuit_breaker_rollback_enabled" {
  type        = bool
  description = "If `true`, Amazon ECS will roll back the service if a service deployment fails. If using `CODE_DEPLOY` for `deployment_controller_type`, this value will be ignored"
  default     = false
}

variable "ephemeral_storage_size" {
  type        = number
  description = "The number of GBs to provision for ephemeral storage on Fargate tasks. Must be greater than or equal to 21 and less than or equal to 200"
  default     = 0

  validation {
    condition     = var.ephemeral_storage_size == 0 || (var.ephemeral_storage_size >= 21 && var.ephemeral_storage_size <= 200)
    error_message = "The ephemeral_storage_size value must be inclusively between 21 and 200."
  }
}

variable "role_tags_enabled" {
  type        = bool
  description = "Whether or not to create tags on ECS roles"
  default     = true
}

variable "ecs_service_enabled" {
  type        = bool
  description = "Whether or not to create the aws_ecs_service resource"
  default     = true
}

variable "ipc_mode" {
  type        = string
  description = <<-EOT
    The IPC resource namespace to be used for the containers in the task.
    The valid values are `host`, `task`, and `none`. If `host` is specified,
    then all containers within the tasks that specified the `host` IPC mode on
    the same container instance share the same IPC resources with the host
    Amazon EC2 instance. If `task` is specified, all containers within the
    specified task share the same IPC resources. If `none` is specified, then
    IPC resources within the containers of a task are private and not shared
    with other containers in a task or on the container instance. If no value
    is specified, then the IPC resource namespace sharing depends on the
    Docker daemon setting on the container instance. For more information, see
    IPC settings in the Docker documentation."
    EOT
  default     = null
  validation {
    condition     = var.ipc_mode == null || contains(["host", "task", "none"], coalesce(var.ipc_mode, "null"))
    error_message = "The ipc_mode value must be one of host, task, or none."
  }
}

variable "pid_mode" {
  type        = string
  description = <<-EOT
    The process namespace to use for the containers in the task. The valid
    values are `host` and `task`. If `host` is specified, then all containers
    within the tasks that specified the `host` PID mode on the same container
    instance share the same process namespace with the host Amazon EC2 instanc
    . If `task` is specified, all containers within the specified task share
    the same process namespace. If no value is specified, then the process
    namespace sharing depends on the Docker daemon setting on the container
    instance. For more information, see PID settings in the Docker documentation.
    EOT
  default     = null
  validation {
    condition     = var.pid_mode == null || contains(["host", "task"], coalesce(var.pid_mode, "null"))
    error_message = "The pid_mode value must be one of host or task."
  }
}

variable "track_latest" {
  type        = bool
  description = "Whether should track latest task definition or the one created with the resource."
  default     = false
}
