data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  log_group_arn = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}"
}

# Prevents another account from using these roles through ECS
data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Used by ECS itself to pull the image and write logs
resource "aws_iam_role" "execution" {
  name               = "${var.name}-execution"
  description        = "ECS task execution role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "execution" {
  # This action does not support resource scoping
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "${var.name}-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# Used by the application code. The API calls no AWS services, so no policy is attached
resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  description        = "ECS task role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}
