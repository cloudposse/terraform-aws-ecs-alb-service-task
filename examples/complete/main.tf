provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.18.1"

  cidr_block = var.vpc_cidr_block

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.33.0"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context = module.this.context
}

resource "aws_ecs_cluster" "default" {
  name = module.this.id
  tags = module.this.tags
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.45.2"

  container_name               = var.container_name
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.container_cpu
  essential                    = var.container_essential
  readonly_root_filesystem     = var.container_readonly_root_filesystem
  environment                  = var.container_environment
  port_mappings                = var.container_port_mappings
}

module "ecs_alb_service_task" {
  source                             = "../.."
  container_definition_json          = module.container_definition.json_map_encoded_list
  ecs_cluster_arn                    = aws_ecs_cluster.default.arn
  launch_type                        = var.ecs_launch_type
  vpc_id                             = module.vpc.vpc_id
  security_groups                    = [module.vpc.vpc_default_security_group_id]
  subnet_ids                         = module.subnets.public_subnet_ids
  ignore_changes_task_definition     = var.ignore_changes_task_definition
  network_mode                       = var.network_mode
  assign_public_ip                   = var.assign_public_ip
  propagate_tags                     = var.propagate_tags
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type         = var.deployment_controller_type
  desired_count                      = var.desired_count
  task_memory                        = var.task_memory
  task_cpu                           = var.task_cpu

  security_group_rules = [
    {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = -1
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = "Allow all outbound traffic"
    },
    {
      type                     = "ingress"
      from_port                = 8
      to_port                  = 0
      protocol                 = "icmp"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = "Enables ping command from anywhere, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html#sg-rules-ping"
    },
    {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      cidr_blocks              = []
      source_security_group_id = module.vpc.vpc_default_security_group_id
      description              = "Allow inbound traffic to container port"
    }
  ]

  context = module.this.context
}
