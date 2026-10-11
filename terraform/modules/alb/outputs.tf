output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.this.arn

  # ECS rejects a target group that is not yet attached to a listener
  depends_on = [aws_lb_listener_rule.this]
}
