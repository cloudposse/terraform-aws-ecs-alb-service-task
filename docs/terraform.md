
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alb_target_group_arn | The ALB target group ARN for the ECS service | string | - | yes |
| attributes | Additional attributes (e.g. `1`) | list | `<list>` | no |
| container_definition_json | The JSON of the task container definition | string | - | yes |
| container_name | The name of the container in task definition to associate with the load balancer | string | - | yes |
| container_port | The port on the container to associate with the load balancer | string | `80` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | string | `-` | no |
| deployment_maximum_percent | The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment | string | `200` | no |
| deployment_minimum_healthy_percent | The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment | string | `100` | no |
| desired_count | The number of instances of the task definition to place and keep running | string | `1` | no |
| ecs_cluster_arn | The ARN of the ECS cluster where service will be provisioned | string | - | yes |
| launch_type | The launch type on which to run your service. Valid values are EC2 and FARGATE | string | `FARGATE` | no |
| name | Solution name, e.g. 'app' or 'cluster' | string | - | yes |
| namespace | Namespace, which could be your organization name, e.g. 'eg' or 'cp' | string | - | yes |
| network_mode | The network mode to use for the task. This is required to be awsvpc for FARGATE `launch_type` | string | `awsvpc` | no |
| private_subnet_ids | Private subnet IDs | list | - | yes |
| security_group_ids | Security group IDs to allow in Service network_configuration | list | - | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | string | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | map | `<map>` | no |
| task_cpu | The number of CPU units used by the task. If using Fargate launch type `task_cpu` must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | string | `256` | no |
| task_memory | The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | string | `512` | no |
| vpc_id | The VPC ID where resources are created | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| service_name | ECS Service name |
| service_role_arn | ECS Service role ARN |
| service_security_group_id | Security Group ID of the ECS task |
| task_role_arn | ECS Task role ARN |
