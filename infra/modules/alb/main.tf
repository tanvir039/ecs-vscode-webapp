resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for the public Application Load Balancer"
  vpc_id      = var.vpc_id

  # Ingress and egress rules are defined in the root module,
  # since they cross-reference the ECS task security group.

  tags = merge(
    var.tags,
    { Name = "${var.name}-alb-sg" }
  )
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = var.public_subnet_ids

  # Kept disabled for this learning project so Terraform can
  # destroy the ALB without additional manual steps.
  enable_deletion_protection = false

  # Must exceed nginx's proxy_read_timeout/proxy_send_timeout (3600s),
  # otherwise the ALB will silently kill long-idle WebSocket connections
  # (e.g. an idle code-server terminal) before nginx would.
  idle_timeout = var.idle_timeout

  # Basic hardening: reject requests with malformed/ambiguous headers
  # rather than passing them through.
  drop_invalid_header_fields = true

  tags = merge(
    var.tags,
    { Name = "${var.name}-alb" }
  )
}

resource "aws_lb_target_group" "app" {
  name = "${var.name}-tg"

  vpc_id      = var.vpc_id
  target_type = "ip"

  port     = var.target_port
  protocol = "HTTP"

  health_check {
    enabled = true

    path     = var.health_check_path
    port     = "traffic-port"
    protocol = "HTTP"
    matcher  = "200"

    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # Shorter than the AWS default (300s) so this lab's teardown/redeploy
  # cycles are faster, while still allowing in-flight requests to drain.
  deregistration_delay = 30

  tags = merge(
    var.tags,
    { Name = "${var.name}-tg" }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    var.tags,
    { Name = "${var.name}-http-redirect-listener" }
  )
}
