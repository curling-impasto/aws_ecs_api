resource "aws_lb_target_group" "this" {
  name        = var.name
  vpc_id      = var.vpc_id
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip" # Required for Fargate awsvpc networking

  # Faster task replacement during rolling deployments
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Added to the shared listener. The ALB does not strip the prefix
resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.listener_rule_priority

  condition {
    path_pattern {
      values = [var.path_prefix, "${var.path_prefix}/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
