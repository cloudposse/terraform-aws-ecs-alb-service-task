data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  appspec_content = "{\"version\": 1,\"Resources\": [{\"TargetService\": {\"Type\": \"AWS::ECS::Service\",\"Properties\": {\"TaskDefinition\": \"${aws_ecs_task_definition.default.arn}\",\"LoadBalancerInfo\": {\"ContainerName\": \"${var.ecs_load_balancers.container_name}\",\"ContainerPort\": ${var.ecs_load_balancers.container_port}}}}]}"
  appspec_sha256 = sha256(local.appspec_content)
}

## IAM

resource "aws_iam_role" "event_bridge_codedeploy" {
  name = "EventBridgeCodeDeploy"
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
  name = "EventBridgeCodeDeployAccess"
  role = aws_iam_role.event_bridge_codedeploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "codedeploy:CreateDeployment"
        Effect   = "Allow"
        Resource = "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${var.ecs_load_balancers.container_name}/${var.ecs_load_balancers.container_name}"
      }
    ]
  })
}

## Event Rule

resource "aws_cloudwatch_event_rule" "ecs_task_state_change" {
  count     = var.deployment_controller_type == "CODEDEPLOY" ? 1 : 0

  name        = "ecs-task-state-change"
  description = "Capture ECS task state changes to trigger CodeDeploy"

  event_pattern = jsonencode({
    source        = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    detail = {
      lastStatus        = ["PENDING", "RUNNING"]
      clusterArn        = var.ecs_cluster_arn
      taskDefinitionArn = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${var.ecs_load_balancers.container_name}:*"]
    }
  })
}

## Event Target

resource "aws_cloudwatch_event_target" "trigger_codedeploy_deployment" {
  count     = var.deployment_controller_type == "CODEDEPLOY" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ecs_task_state_change.name
  target_id = "TriggerCodeDeploy"
  arn       = "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${var.ecs_load_balancers.container_name}/${var.ecs_load_balancers.container_name}"
  role_arn  = aws_iam_role.event_bridge_codedeploy.arn

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
  "deploymentGroupName": "${var.ecs_load_balancers.container_name}"
}
EOF
  }
}