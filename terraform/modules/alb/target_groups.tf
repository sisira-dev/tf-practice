# ALB Target Group Module (called by main.tf)

resource "aws_lb_target_group" "main" {
  for_each = toset(var.services)

  name_prefix = each.value != "" ? substr(replace(each.value, "-", ""), 0, 6) : "tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
  }

  tags = {
    Name        = "${var.project_name}-${each.value}-tg"
    Environment = var.environment
    Service     = each.value
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Listener Rules for routing by path or hostname
resource "aws_lb_listener_rule" "path_based" {
  for_each = toset(var.services)

  listener_arn = local.listener_arn
  priority     = index(var.services, each.value) + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.value].arn
  }

  condition {
    path_pattern {
      values = ["/${each.value}/*", "/${each.value}"]
    }
  }
}
