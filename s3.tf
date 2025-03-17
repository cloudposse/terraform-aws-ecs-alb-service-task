## S3 Bucket for applications with CodeDeploy enabled only
locals {
  container_definitions = try(jsondecode(var.container_definition_json), var.container_definition_json)
  taskdef_content = jsonencode({
    family               = var.ecs_service_name != null ? var.ecs_service_name : module.service_label.id
    containerDefinitions = local.container_definitions
    executionRoleArn     = length(local.task_exec_role_arn) > 0 ? local.task_exec_role_arn : one(aws_iam_role.ecs_exec[*]["arn"])
    networkMode          = var.network_mode
    cpu                  = tostring(var.task_cpu)
    memory               = tostring(var.task_memory)
  })
  appspec_content = <<YAML
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${aws_ecs_task_definition.default[0].arn}"
        LoadBalancerInfo:
          ContainerName: "${local.container_name}"
          ContainerPort: ${local.container_port}
YAML
}

data "archive_file" "appspec" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  type = "zip"
  source {
    content  = local.appspec_content
    filename = "appspec.yml"
  }
  source {
    content  = local.taskdef_content
    filename = "taskdef.json"
  }
  output_path = "${path.module}/appspec.zip"
}

resource "aws_s3_object" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = aws_s3_bucket.appspec_artifacts[0].id
  key    = "source/appspec.zip"
  source = data.archive_file.appspec[0].output_path
  etag   = sha256("${local.appspec_content}${local.taskdef_content}")
  tags   = module.this.tags
}

resource "aws_s3_bucket" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = "${module.this.stage}-codedeploy-${local.container_name}-appspec"
  tags   = module.this.tags
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = aws_s3_bucket.appspec_artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "appspec_artifacts" {
  count = var.deployment_controller_type == "CODE_DEPLOY" ? 1 : 0

  bucket = aws_s3_bucket.appspec_artifacts[0].id
  rule {
    id     = "manage-old-versions"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 60
    }
  }
}