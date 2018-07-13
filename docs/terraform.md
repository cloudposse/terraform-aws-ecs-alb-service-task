
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alb_target_group_arn | The ALB target group ARN for the ECS service. | string | - | yes |
| attributes | List of attributes to add to label. | list | `<list>` | no |
| container_definition_json | The JSON of the task container definition. | string | - | yes |
| container_name | The name of the container in task definition to associate with the load balancer. | string | - | yes |
| container_port | The port on the container to associate with the load balancer. | string | `80` | no |
| delimiter | The delimiter to be used in labels. | string | `-` | no |
| deployment_maximum_percent | The upper limit of the number of tasks (as a percentage of desired_count) that can be running in a service during a deployment. | string | `200` | no |
| deployment_minimum_healthy_percent | The lower limit (as a percentage of desired_count) of the number of tasks that must remain running and healthy in a service during a deployment. | string | `100` | no |
| desired_count | The number of instances of the task definition to place and keep running. | string | `1` | no |
| ecr_repository_name | The name of the ECR repository to store images. | string | - | yes |
| ecs_cluster_arn | The ARN of the ECS cluster where service will be provisioned. | string | - | yes |
| family | The name used for multiple versions of a task definition. | string | `web` | no |
| launch_type | The launch type on which to run your service. Valid values are EC2 and FARGATE. | string | `FARGATE` | no |
| name | The name of the app to be used in labels. | string | - | yes |
| namespace | The namespace to be used in labels. | string | - | yes |
| network_mode | The network mode to use for the task. This is required to be awsvpc for FARGATE launch_type. | string | `awsvpc` | no |
| private_subnet_ids | Private subnet IDs. | list | - | yes |
| security_group_ids | Security group IDs to allow in Service network_configuration. | list | - | yes |
| stage | Stage to be used in labels. | string | - | yes |
| tags | Map of key-value pairs to use for tags. | map | `<map>` | no |
| task_cpu | The number of CPU units used by the task. If using Fargate launch type task_cpu must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size). | string | `256` | no |
| task_memory | The amount of memory (in MiB) used by the task. If using Fargate launch type task_memory must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size). | string | `512` | no |
| vpc_id | The VPC ID where resources are created. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| service_name | ECS Service name |
| service_role_arn | ECS Service role ARN |
| task_role_arn | ECS Task role ARN |

