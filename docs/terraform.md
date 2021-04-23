<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.34 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.3 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.34 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_exec_label"></a> [exec\_label](#module\_exec\_label) | cloudposse/label/null | 0.24.1 |
| <a name="module_service_label"></a> [service\_label](#module\_service\_label) | cloudposse/label/null | 0.24.1 |
| <a name="module_task_label"></a> [task\_label](#module\_task\_label) | cloudposse/label/null | 0.24.1 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.24.1 |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.ignore_changes_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ecs_ssm_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_all_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_icmp_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_policy_document.ecs_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_service_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_ssm_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional tags for appending to tags\_as\_list\_of\_maps. Not added to `tags`. | `map(string)` | `{}` | no |
| <a name="input_alb_security_group"></a> [alb\_security\_group](#input\_alb\_security\_group) | Security group of the ALB | `string` | `""` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI (Fargate launch type only). Valid values are `true` or `false`. Default `false` | `bool` | `false` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| <a name="input_capacity_provider_strategies"></a> [capacity\_provider\_strategies](#input\_capacity\_provider\_strategies) | The capacity provider strategies to use for the service. See `capacity_provider_strategy` configuration block: https://www.terraform.io/docs/providers/aws/r/ecs_service.html#capacity_provider_strategy | <pre>list(object({<br>    capacity_provider = string<br>    weight            = number<br>    base              = number<br>  }))</pre> | `[]` | no |
| <a name="input_container_definition_json"></a> [container\_definition\_json](#input\_container\_definition\_json) | A string containing a JSON-encoded array of container definitions<br>(`"[{ "name": "container1", ... }, { "name": "container2", ... }]"`).<br>See [API\_ContainerDefinition](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html),<br>[cloudposse/terraform-aws-ecs-container-definition](https://github.com/cloudposse/terraform-aws-ecs-container-definition), or<br>[ecs\_task\_definition#container\_definitions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#container_definitions) | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port on the container to allow via the ingress security group | `number` | `80` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {}<br>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_deployment_controller_type"></a> [deployment\_controller\_type](#input\_deployment\_controller\_type) | Type of deployment controller. Valid values are `CODE_DEPLOY` and `ECS` | `string` | `"ECS"` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The number of instances of the task definition to place and keep running | `number` | `1` | no |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | The ARN of the ECS cluster where service will be provisioned | `string` | n/a | yes |
| <a name="input_ecs_load_balancers"></a> [ecs\_load\_balancers](#input\_ecs\_load\_balancers) | A list of load balancer config objects for the ECS service; see [ecs\_service#load\_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#load_balancer) docs | <pre>list(object({<br>    container_name   = string<br>    container_port   = number<br>    elb_name         = string<br>    target_group_arn = string<br>  }))</pre> | `[]` | no |
| <a name="input_enable_all_egress_rule"></a> [enable\_all\_egress\_rule](#input\_enable\_all\_egress\_rule) | A flag to enable/disable adding the all ports egress rule to the ECS security group | `bool` | `true` | no |
| <a name="input_enable_ecs_managed_tags"></a> [enable\_ecs\_managed\_tags](#input\_enable\_ecs\_managed\_tags) | Specifies whether to enable Amazon ECS managed tags for the tasks within the service | `bool` | `false` | no |
| <a name="input_enable_icmp_rule"></a> [enable\_icmp\_rule](#input\_enable\_icmp\_rule) | Specifies whether to enable ICMP on the security group | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment, e.g. 'uw2', 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_exec_enabled"></a> [exec\_enabled](#input\_exec\_enabled) | Specifies whether to enable Amazon ECS Exec for the tasks within the service | `bool` | `false` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Enable to force a new task deployment of the service. | `bool` | `false` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers | `number` | `0` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for default, which is `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ignore_changes_task_definition"></a> [ignore\_changes\_task\_definition](#input\_ignore\_changes\_task\_definition) | Whether to ignore changes in container definition and task definition in the ECS service | `bool` | `true` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | The letter case of label keys (`tag` names) (i.e. `name`, `namespace`, `environment`, `stage`, `attributes`) to use in `tags`.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The naming order of the id output and Name tag.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 5 elements, but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | The letter case of output label values (also used in `tags` and `id`).<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Default value: `lower`. | `string` | `null` | no |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | The launch type on which to run your service. Valid values are `EC2` and `FARGATE` | `string` | `"FARGATE"` | no |
| <a name="input_name"></a> [name](#input\_name) | Solution name, e.g. 'app' or 'jenkins' | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `null` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | The network mode to use for the task. This is required to be `awsvpc` for `FARGATE` `launch_type` or `null` for `EC2` `launch_type` | `string` | `"awsvpc"` | no |
| <a name="input_nlb_cidr_blocks"></a> [nlb\_cidr\_blocks](#input\_nlb\_cidr\_blocks) | A list of CIDR blocks to add to the ingress rule for the NLB container port | `list(string)` | `[]` | no |
| <a name="input_nlb_container_port"></a> [nlb\_container\_port](#input\_nlb\_container\_port) | The port on the container to allow via the ingress security group | `number` | `80` | no |
| <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy) | Service level strategy rules that are taken into consideration during task placement.<br>List from top to bottom in order of precedence. The maximum number of ordered\_placement\_strategy blocks is 5.<br>See [`ordered_placement_strategy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service#ordered_placement_strategy) | <pre>list(object({<br>    type  = string<br>    field = string<br>  }))</pre> | `[]` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | A permissions boundary ARN to apply to the 3 roles that are created. | `string` | `""` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | The platform version on which to run your service. Only applicable for `launch_type` set to `FARGATE`.<br>More information about Fargate platform versions can be found in the AWS ECS User Guide. | `string` | `"LATEST"` | no |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK\_DEFINITION | `string` | `null` | no |
| <a name="input_proxy_configuration"></a> [proxy\_configuration](#input\_proxy\_configuration) | The proxy configuration details for the App Mesh proxy. See `proxy_configuration` docs https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#proxy-configuration-arguments | <pre>object({<br>    type           = string<br>    container_name = string<br>    properties     = map(string)<br>  })</pre> | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | The scheduling strategy to use for the service. The valid values are `REPLICA` and `DAEMON`.<br>Note that Fargate tasks do not support the DAEMON scheduling strategy. | `string` | `"REPLICA"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group IDs to allow in Service `network_configuration` if `var.network_mode = "awsvpc"` | `list(string)` | `[]` | no |
| <a name="input_service_placement_constraints"></a> [service\_placement\_constraints](#input\_service\_placement\_constraints) | The rules that are taken into consideration during task placement. Maximum number of placement\_constraints is 10. See [`placement_constraints`](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#placement_constraints-1) docs | <pre>list(object({<br>    type       = string<br>    expression = string<br>  }))</pre> | `[]` | no |
| <a name="input_service_registries"></a> [service\_registries](#input\_service\_registries) | The service discovery registries for the service. The maximum number of service\_registries blocks is 1. The currently supported service registry is Amazon Route 53 Auto Naming Service - `aws_service_discovery_service`; see `service_registries` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1 | <pre>list(object({<br>    registry_arn   = string<br>    port           = number<br>    container_name = string<br>    container_port = number<br>  }))</pre> | `[]` | no |
| <a name="input_service_role_arn"></a> [service\_role\_arn](#input\_service\_role\_arn) | ARN of the IAM role that allows Amazon ECS to make calls to your load balancer on your behalf. This parameter is required if you are using a load balancer with your service, but only if your task definition does not use the awsvpc network mode. If using awsvpc network mode, do not specify this role. If your account has already created the Amazon ECS service-linked role, that role is used by default for your service unless you specify a role here. | `string` | `null` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs used in Service `network_configuration` if `var.network_mode = "awsvpc"` | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | The number of CPU units used by the task. If using `FARGATE` launch type `task_cpu` must match [supported memory values](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | `number` | `256` | no |
| <a name="input_task_definition"></a> [task\_definition](#input\_task\_definition) | Reuse an existing task definition family and revision for the ecs service instead of creating one | `string` | `null` | no |
| <a name="input_task_exec_policy_arns"></a> [task\_exec\_policy\_arns](#input\_task\_exec\_policy\_arns) | A list of IAM Policy ARNs to attach to the generated task execution role. | `list(string)` | `[]` | no |
| <a name="input_task_exec_role_arn"></a> [task\_exec\_role\_arn](#input\_task\_exec\_role\_arn) | The ARN of IAM role that allows the ECS/Fargate agent to make calls to the ECS API on your behalf | `string` | `""` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match [supported cpu value](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size) | `number` | `512` | no |
| <a name="input_task_placement_constraints"></a> [task\_placement\_constraints](#input\_task\_placement\_constraints) | A set of placement constraints rules that are taken into consideration during task placement.<br>Maximum number of placement\_constraints is 10. See [`placement_constraints`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#placement-constraints-arguments) | <pre>list(object({<br>    type       = string<br>    expression = string<br>  }))</pre> | `[]` | no |
| <a name="input_task_policy_arns"></a> [task\_policy\_arns](#input\_task\_policy\_arns) | A list of IAM Policy ARNs to attach to the generated task role. | `list(string)` | `[]` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | The ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services | `string` | `""` | no |
| <a name="input_use_alb_security_group"></a> [use\_alb\_security\_group](#input\_use\_alb\_security\_group) | A flag to enable/disable adding the ingress rule to the ALB security group | `bool` | `false` | no |
| <a name="input_use_nlb_cidr_blocks"></a> [use\_nlb\_cidr\_blocks](#input\_use\_nlb\_cidr\_blocks) | A flag to enable/disable adding the NLB ingress rule to the security group | `bool` | `false` | no |
| <a name="input_use_old_arn"></a> [use\_old\_arn](#input\_use\_old\_arn) | A flag to enable/disable tagging the ecs resources that require the new arn format | `bool` | `false` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Task volume definitions as list of configuration objects | <pre>list(object({<br>    host_path = string<br>    name      = string<br>    docker_volume_configuration = list(object({<br>      autoprovision = bool<br>      driver        = string<br>      driver_opts   = map(string)<br>      labels        = map(string)<br>      scope         = string<br>    }))<br>    efs_volume_configuration = list(object({<br>      file_system_id          = string<br>      root_directory          = string<br>      transit_encryption      = string<br>      transit_encryption_port = string<br>      authorization_config = list(object({<br>        access_point_id = string<br>        iam             = string<br>      }))<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID where resources are created | `string` | n/a | yes |
| <a name="input_wait_for_steady_state"></a> [wait\_for\_steady\_state](#input\_wait\_for\_steady\_state) | If true, it will wait for the service to reach a steady state (like aws ecs wait services-stable) before continuing | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_exec_role_policy_id"></a> [ecs\_exec\_role\_policy\_id](#output\_ecs\_exec\_role\_policy\_id) | The ECS service role policy ID, in the form of `role_name:role_policy_name` |
| <a name="output_ecs_exec_role_policy_name"></a> [ecs\_exec\_role\_policy\_name](#output\_ecs\_exec\_role\_policy\_name) | ECS service role name |
| <a name="output_service_arn"></a> [service\_arn](#output\_service\_arn) | ECS Service ARN |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | ECS Service name |
| <a name="output_service_role_arn"></a> [service\_role\_arn](#output\_service\_role\_arn) | ECS Service role ARN |
| <a name="output_service_security_group_id"></a> [service\_security\_group\_id](#output\_service\_security\_group\_id) | Security Group ID of the ECS task |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | ECS task definition family |
| <a name="output_task_definition_revision"></a> [task\_definition\_revision](#output\_task\_definition\_revision) | ECS task definition revision |
| <a name="output_task_exec_role_arn"></a> [task\_exec\_role\_arn](#output\_task\_exec\_role\_arn) | ECS Task exec role ARN |
| <a name="output_task_exec_role_name"></a> [task\_exec\_role\_name](#output\_task\_exec\_role\_name) | ECS Task role name |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | ECS Task role ARN |
| <a name="output_task_role_id"></a> [task\_role\_id](#output\_task\_role\_id) | ECS Task role id |
| <a name="output_task_role_name"></a> [task\_role\_name](#output\_task\_role\_name) | ECS Task role name |
<!-- markdownlint-restore -->
