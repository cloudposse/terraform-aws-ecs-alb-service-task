// IAM
resource "aws_iam_role" "default" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  name = "${module.this.id}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codepipeline.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "default" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  role = aws_iam_role.default.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.appspec_artifacts[0].arn,
          "${aws_s3_bucket.appspec_artifacts[0].arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "codedeploy:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "codepipeline:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = aws_iam_role.ecs_exec[0].arn
      }
    ]
  })
}

// CodePipeline
resource "aws_codepipeline" "default" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  name     = local.container_name
  role_arn = aws_iam_role.default.arn

  artifact_store {
    location = aws_s3_bucket.appspec_artifacts[0].bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "S3Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        S3Bucket    = aws_s3_bucket.appspec_artifacts[0].bucket
        S3ObjectKey = "source/appspec.zip"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "CodeDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["SourceOutput"]
      configuration = {
        ApplicationName                = local.container_name
        DeploymentGroupName            = local.container_name
        TaskDefinitionTemplateArtifact = "SourceOutput"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "SourceOutput"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }
  }
  depends_on = [aws_s3_object.appspec_artifacts]
}
