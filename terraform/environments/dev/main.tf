locals {
  log_group_name = "/ecs/${var.project_name}"
}

module "iam" {
  source = "../../modules/iam"

  name               = var.project_name
  ecr_repository_arn = data.aws_ecr_repository.shared.arn
  log_group_name     = local.log_group_name
}

module "alb" {
  source = "../../modules/alb"

  name                   = var.project_name
  vpc_id                 = var.vpc_id
  listener_arn           = var.alb_listener_arn
  listener_rule_priority = var.listener_rule_priority
  path_prefix            = var.route_prefix
  container_port         = var.container_port
}

module "ecs" {
  source = "../../modules/ecs"

  name                  = var.project_name
  cluster_arn           = var.ecs_cluster_arn
  vpc_id                = var.vpc_id
  subnet_ids            = var.subnet_ids
  alb_security_group_id = var.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  container_port        = var.container_port
  image                 = "${data.aws_ecr_repository.shared.repository_url}:${var.image_tag}"
  cpu                   = var.cpu
  memory                = var.memory
  desired_count         = var.desired_count
  execution_role_arn    = module.iam.execution_role_arn
  task_role_arn         = module.iam.task_role_arn
  log_group_name        = local.log_group_name
  route_prefix          = var.route_prefix
}
