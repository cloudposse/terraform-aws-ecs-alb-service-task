## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alb_security_group | Security group of the ALB | string | - | yes |
| assign_public_ip | Assign a public IP address to the ENI (Fargate launch type only). Valid values are `true` or `false`. Default `false` | bool | `false` | no |
| attributes | Additional attributes (_e.g._ "1") | list(string) | `<list>` | no |
| container_definition_json | The JSON of the task container definition | string | - | yes |
| container_port | The port on the container to allow via the ingress security group | number | `80` | no |
| delimiter | Delimiter between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| deployment_controller_type | Type of deployment controller. Valid values: `CODE_DEPLOY` and `ECS` | string | `ECS` | no |
| deployment_maximum_percent | The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment | number | `200` | no |
| deployment_minimum_healthy_percent | The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment | number | `100` | no |
| desired_count | The number of instances of the task definition to place and keep running | number | `1` | no |
| ecs_cluster_arn | The ARN of the ECS cluster where service will be provisioned | string | - | yes |
| ecs_load_balancers | A list of load balancer config objects for the ECS service; see `load_balancer` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html | object | `<list>` | no |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| health_check_grace_period_seconds | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers | number | `0` | no |
| ignore_changes_task_definition | Whether to ignore changes in container definition and task definition in the ECS service | bool | `true` | no |
| launch_type | The launch type on which to run your service. Valid values are `EC2` and `FARGATE` | string | `FARGATE` | no |
| name | Name of the application | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | `` | no |
| network_mode | The network mode to use for the task. This is required to be awsvpc for `FARGATE` `launch_type` | string | `awsvpc` | no |
| propagate_tags | Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION | string | `null` | no |
| security_group_ids | Security group IDs to allow in Service `network_configuration` | list(string) | - | yes |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | `` | no |
| subnet_ids | Subnet IDs | list(string) | - | yes |
| tags | Additional tags (_e.g._ { BusinessUnit : ABC }) | map(string) | `<map>` | no |
| task_cpu | The number of CPU units used by the task. If using `FARGATE` launch type `task_cpu` must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | number | `256` | no |
| task_memory | The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | number | `512` | no |
| volumes | Task volume definitions as list of configuration objects | object | `<list>` | no |
| vpc_id | The VPC ID where resources are created | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs_exec_role_policy_id | The ECS service role policy ID, in the form of `role_name:role_policy_name` |
| ecs_exec_role_policy_name | ECS service role name |
| service_name | ECS Service name |
| service_role_arn | ECS Service role ARN |
| service_security_group_id | Security Group ID of the ECS task |
| task_definition_family | ECS task definition family |
| task_definition_revision | ECS task definition revision |
| task_exec_role_arn | ECS Task exec role ARN |
| task_exec_role_name | ECS Task role name |
| task_role_arn | ECS Task role ARN |
| task_role_id | ECS Task role id |
| task_role_name | ECS Task role name |

