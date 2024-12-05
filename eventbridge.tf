data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  container_name  = length(var.ecs_load_balancers) > 0 ? var.ecs_load_balancers[0].container_name : "rift"
  container_port  = length(var.ecs_load_balancers) > 0 ? var.ecs_load_balancers[0].container_port : "80"
  appspec_content = "{\"version\": 1,\"Resources\": [{\"TargetService\": {\"Type\": \"AWS::ECS::Service\",\"Properties\": {\"TaskDefinition\": \"${aws_ecs_task_definition.default[0].arn}\",\"LoadBalancerInfo\": {\"ContainerName\": \"${local.container_name}\",\"ContainerPort\": ${local.container_port}}}}]}"
  appspec_sha256  = sha256(local.appspec_content)
}

## IAM

resource "aws_iam_role" "event_bridge_codedeploy" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  name = "EventBridgeCodeDeploy-${var.ecs_load_balancers[0].container_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazon.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "event_bridge_codedeploy" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  name = "EventBridgeCodeDeployAccess-${var.ecs_load_balancers[0].container_name}"
  role = aws_iam_role.event_bridge_codedeploy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "codedeploy:CreateDeployment"
        Effect   = "Allow"
        Resource = "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${local.container_name}/${local.container_name}"
      }
    ]
  })

  depends_on = [aws_iam_role.event_bridge_codedeploy]
}

## Event Rule

resource "aws_cloudwatch_event_rule" "ecs_task_state_change" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  name        = "ecs-task-state-change-${local.container_name}"
  description = "Capture ECS task state changes to trigger CodeDeploy"

  event_pattern = jsonencode({
    source        = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    detail = {
      lastStatus        = ["PENDING", "RUNNING"]
      clusterArn        = var.ecs_cluster_arn
      taskDefinitionArn = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${local.container_name}:*"]
    }
  })
}

## Event Target

resource "aws_cloudwatch_event_target" "trigger_codedeploy_deployment" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ecs_task_state_change[0].name
  target_id = "TriggerCodeDeploy"
  arn       = "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${local.container_name}/${local.container_port}"
  role_arn  = aws_iam_role.event_bridge_codedeploy[0].arn

  input_transformer {
    input_paths = {
      "taskDefinitionArn" = "$.detail.taskDefinitionArn"
    }
    input_template = <<EOF
{
  "revisionType": "AppSpecContent",
  "appSpecContent": {
    "content": "${local.appspec_content}",
    "sha256": "${local.appspec_sha256}"
  },
  "deploymentGroupName": "${local.container_name}"
}
EOF
  }

  depends_on = [
    aws_cloudwatch_event_rule.ecs_task_state_change,
    aws_iam_role.event_bridge_codedeploy
  ]
}