<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 2.0 |
| local | >= 1.3 |
| null | >= 2.0 |
| template | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| exec_label | cloudposse/label/null | 0.24.1 |
| service_label | cloudposse/label/null | 0.24.1 |
| task_label | cloudposse/label/null | 0.24.1 |
| this | cloudposse/label/null | 0.24.1 |

## Resources

| Name |
|------|
| [aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_tag\_map | Additional tags for appending to tags\_as\_list\_of\_maps. Not added to `tags`. | `map(string)` | `{}` | no |
| alb\_security\_group | Security group of the ALB | `string` | `""` | no |
| assign\_public\_ip | Assign a public IP address to the ENI (Fargate launch type only). Valid values are `true` or `false`. Default `false` | `bool` | `false` | no |
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| capacity\_provider\_strategies | The capacity provider strategies to use for the service. See `capacity_provider_strategy` configuration block: https://www.terraform.io/docs/providers/aws/r/ecs_service.html#capacity_provider_strategy | <pre>list(object({<br>    capacity_provider = string<br>    weight            = number<br>    base              = number<br>  }))</pre> | `[]` | no |
| container\_definition\_json | A string containing a JSON-encoded array of container definitions<br>(`"[{ "name": "container1", ... }, { "name": "container2", ... }]"`).<br>See [AWS docs](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html),<br>https://github.com/cloudposse/terraform-aws-ecs-container-definition, or<br>[Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#container_definitions) | `string` | n/a | yes |
| container\_port | The port on the container to allow via the ingress security group | `number` | `80` | no |
| context | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {}<br>}</pre> | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| deployment\_controller\_type | Type of deployment controller. Valid values are `CODE_DEPLOY` and `ECS` | `string` | `"ECS"` | no |
| deployment\_maximum\_percent | The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment | `number` | `200` | no |
| deployment\_minimum\_healthy\_percent | The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment | `number` | `100` | no |
| desired\_count | The number of instances of the task definition to place and keep running | `number` | `1` | no |
| ecs\_cluster\_arn | The ARN of the ECS cluster where service will be provisioned | `string` | n/a | yes |
| ecs\_load\_balancers | A list of load balancer config objects for the ECS service; see `load_balancer` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html | <pre>list(object({<br>    container_name   = string<br>    container_port   = number<br>    elb_name         = string<br>    target_group_arn = string<br>  }))</pre> | `[]` | no |
| enable\_all\_egress\_rule | A flag to enable/disable adding the all ports egress rule to the ECS security group | `bool` | `true` | no |
| enable\_ecs\_managed\_tags | Specifies whether to enable Amazon ECS managed tags for the tasks within the service | `bool` | `false` | no |
| enable\_icmp\_rule | Specifies whether to enable ICMP on the security group | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| environment | Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| health\_check\_grace\_period\_seconds | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers | `number` | `0` | no |
| id\_length\_limit | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for default, which is `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| ignore\_changes\_task\_definition | Whether to ignore changes in container definition and task definition in the ECS service | `bool` | `true` | no |
| label\_key\_case | The letter case of label keys (`tag` names) (i.e. `name`, `namespace`, `environment`, `stage`, `attributes`) to use in `tags`.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| label\_order | The naming order of the id output and Name tag.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 5 elements, but at least one must be present. | `list(string)` | `null` | no |
| label\_value\_case | The letter case of output label values (also used in `tags` and `id`).<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Default value: `lower`. | `string` | `null` | no |
| launch\_type | The launch type on which to run your service. Valid values are `EC2` and `FARGATE` | `string` | `"FARGATE"` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `null` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `null` | no |
| network\_mode | The network mode to use for the task. This is required to be `awsvpc` for `FARGATE` `launch_type` | `string` | `"awsvpc"` | no |
| nlb\_cidr\_blocks | A list of CIDR blocks to add to the ingress rule for the NLB container port | `list(string)` | `[]` | no |
| nlb\_container\_port | The port on the container to allow via the ingress security group | `number` | `80` | no |
| ordered\_placement\_strategy | Service level strategy rules that are taken into consideration during task placement.<br>List from top to bottom in order of precedence. The maximum number of ordered\_placement\_strategy blocks is 5.<br>See `ordered_placement_strategy` [Terraform docs](<br>https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#ordered_placement_strategy) | <pre>list(object({<br>    type  = string<br>    field = string<br>  }))</pre> | `[]` | no |
| permissions\_boundary | A permissions boundary ARN to apply to the 3 roles that are created. | `string` | `""` | no |
| platform\_version | The platform version on which to run your service. Only applicable for launch\_type set to FARGATE.<br>More information about Fargate platform versions can be found in the AWS ECS User Guide. | `string` | `"LATEST"` | no |
| propagate\_tags | Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK\_DEFINITION | `string` | `null` | no |
| proxy\_configuration | The proxy configuration details for the App Mesh proxy. See `proxy_configuration` docs https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#proxy-configuration-arguments | <pre>object({<br>    type           = string<br>    container_name = string<br>    properties     = map(string)<br>  })</pre> | `null` | no |
| regex\_replace\_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| scheduling\_strategy | The scheduling strategy to use for the service. The valid values are REPLICA and DAEMON.<br>Note that Fargate tasks do not support the DAEMON scheduling strategy. | `string` | `"REPLICA"` | no |
| security\_group\_ids | Security group IDs to allow in Service `network_configuration` | `list(string)` | `[]` | no |
| service\_placement\_constraints | The rules that are taken into consideration during task placement. Maximum number of placement\_constraints is 10. See `placement_constraints` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html#placement_constraints-1 | <pre>list(object({<br>    type       = string<br>    expression = string<br>  }))</pre> | `[]` | no |
| service\_registries | The service discovery registries for the service. The maximum number of service\_registries blocks is 1. The currently supported service registry is Amazon Route 53 Auto Naming Service - `aws_service_discovery_service`; see `service_registries` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1 | <pre>list(object({<br>    registry_arn   = string<br>    port           = number<br>    container_name = string<br>    container_port = number<br>  }))</pre> | `[]` | no |
| service\_role\_arn | ARN of the IAM role that allows Amazon ECS to make calls to your load balancer on your behalf. This parameter is required if you are using a load balancer with your service, but only if your task definition does not use the awsvpc network mode. If using awsvpc network mode, do not specify this role. If your account has already created the Amazon ECS service-linked role, that role is used by default for your service unless you specify a role here. | `string` | `null` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| subnet\_ids | Subnet IDs | `list(string)` | `null` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| task\_cpu | The number of CPU units used by the task. If using `FARGATE` launch type `task_cpu` must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | `number` | `256` | no |
| task\_exec\_policy\_arns | A list of IAM Policy ARNs to attach to the generated task execution role. | `list(string)` | `[]` | no |
| task\_exec\_role\_arn | The ARN of IAM role that allows the ECS/Fargate agent to make calls to the ECS API on your behalf | `string` | `""` | no |
| task\_memory | The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | `number` | `512` | no |
| task\_placement\_constraints | A set of placement constraints rules that are taken into consideration during task placement.<br>Maximum number of placement\_constraints is 10. See `placement_constraints` [Terraform docs](<br>https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#placement-constraints-arguments) | <pre>list(object({<br>    type       = string<br>    expression = string<br>  }))</pre> | `[]` | no |
| task\_policy\_arns | A list of IAM Policy ARNs to attach to the generated task role. | `list(string)` | `[]` | no |
| task\_role\_arn | The ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services | `string` | `""` | no |
| use\_alb\_security\_group | A flag to enable/disable adding the ingress rule to the ALB security group | `bool` | `false` | no |
| use\_nlb\_cidr\_blocks | A flag to enable/disable adding the NLB ingress rule to the security group | `bool` | `false` | no |
| use\_old\_arn | A flag to enable/disable tagging the ecs resources that require the new arn format | `bool` | `false` | no |
| volumes | Task volume definitions as list of configuration objects | <pre>list(object({<br>    host_path = string<br>    name      = string<br>    docker_volume_configuration = list(object({<br>      autoprovision = bool<br>      driver        = string<br>      driver_opts   = map(string)<br>      labels        = map(string)<br>      scope         = string<br>    }))<br>    efs_volume_configuration = list(object({<br>      file_system_id          = string<br>      root_directory          = string<br>      transit_encryption      = string<br>      transit_encryption_port = string<br>      authorization_config = list(object({<br>        access_point_id = string<br>        iam             = string<br>      }))<br>    }))<br>  }))</pre> | `[]` | no |
| vpc\_id | The VPC ID where resources are created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs\_exec\_role\_policy\_id | The ECS service role policy ID, in the form of `role_name:role_policy_name` |
| ecs\_exec\_role\_policy\_name | ECS service role name |
| service\_arn | ECS Service ARN |
| service\_name | ECS Service name |
| service\_role\_arn | ECS Service role ARN |
| service\_security\_group\_id | Security Group ID of the ECS task |
| task\_definition\_family | ECS task definition family |
| task\_definition\_revision | ECS task definition revision |
| task\_exec\_role\_arn | ECS Task exec role ARN |
| task\_exec\_role\_name | ECS Task role name |
| task\_role\_arn | ECS Task role ARN |
| task\_role\_id | ECS Task role id |
| task\_role\_name | ECS Task role name |
<!-- markdownlint-restore -->
