module "label" {
  source     = "github.com/cloudposse/terraform-terraform-label.git?ref=master"
  attributes = "${var.attributes}"
  delimiter  = "${var.delimiter}"
  name       = "${var.name}"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  tags       = "${var.tags}"
}

# Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name = "${module.label.id}"

  tags {
    Stage       = "${module.label.stage}"
    Application = "${module.label.name}"
  }
}

# ECR repository
data "aws_ecr_repository" "app" {
  name = "${var.ecr_repository_name}"
}

resource "aws_ecs_task_definition" "default" {
  family                   = "${var.family}"
  container_definitions    = "${var.container_definition_json}"
  requires_compatibilities = ["${var.launch_type}"]
  network_mode             = "${var.network_mode}"
  cpu                      = "${var.task_cpu}"
  memory                   = "${var.task_memory}"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.ecs_execution_role.arn}"
}

# ALB

## Target Group
resource "random_id" "target_group_suffix" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name        = "${module.label.id}-${random_id.target_group_suffix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

## Listener
resource "aws_alb_listener" "app" {
  load_balancer_arn = "${var.alb_arn}"
  port              = "80"
  protocol          = "HTTP"
  depends_on        = ["aws_alb_target_group.alb_target_group"]

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    type             = "forward"
  }
}

# IAM
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = "${data.aws_iam_policy_document.ecs_service_policy.json}"
  role   = "${aws_iam_role.ecs_role.id}"
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_execution_role.json}"
}

data "aws_iam_policy_document" "ecs_execution_role" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = "${data.aws_iam_policy_document.ecs_execution_role.json}"
  role   = "${aws_iam_role.ecs_execution_role.id}"
}

# Service
##  ECS cluster
data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.ecs_cluster_name}"
}

## Security Groups
resource "aws_security_group" "ecs_service" {
  vpc_id      = "${var.vpc_id}"
  name        = "${module.label.stage}-ecs-service"
  description = "Allow egress from container"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name  = "${module.label.stage}-ecs-service"
    Stage = "${module.label.stage}"
  }
}

data "aws_ecs_task_definition" "default" {
  depends_on      = ["aws_ecs_task_definition.default"]
  task_definition = "${aws_ecs_task_definition.default.family}"
}

resource "aws_ecs_service" "default" {
  name            = "${module.label.id}"
  task_definition = "${aws_ecs_task_definition.default.family}:${max(aws_ecs_task_definition.default.revision, data.aws_ecs_task_definition.default.revision)}"
  desired_count   = "${var.desired_count}"
  launch_type     = "${var.launch_type}"
  cluster         = "${data.aws_ecs_cluster.cluster.arn}"
  depends_on      = ["aws_iam_role_policy.ecs_service_role_policy"]

  network_configuration {
    security_groups = ["${var.security_group_ids}", "${aws_security_group.ecs_service.id}"]
    subnets         = ["${var.private_subnet_ids}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    container_name   = "${var.name}"                                  #FIXME
    container_port   = 80                                             #FIXME
  }

  depends_on = ["aws_alb_target_group.alb_target_group"]
}
