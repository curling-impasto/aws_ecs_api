data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
}

resource "aws_security_group" "task" {
  name        = "${var.name}-task"
  description = "Task security group"
  vpc_id      = var.vpc_id
}

# Only the load balancer can reach the task
resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.task.id
  referenced_security_group_id = var.alb_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  description                  = "From load balancer"
}

# Required to pull images and send logs through the NAT
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.task.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound"
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "PORT", value = tostring(var.container_port) },
      { name = "ROUTE_PREFIX", value = var.route_prefix },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = var.name
      }
    }
  }])
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  # Rolling update: start new tasks first, never drop below full capacity
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Gives the app time to start before health checks count
  health_check_grace_period_seconds = var.health_check_grace_period

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.container_port
  }

  # The deploy pipeline registers new task definition revisions
  lifecycle {
    ignore_changes = [task_definition]
  }
}
