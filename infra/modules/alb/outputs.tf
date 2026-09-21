output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB, required for Route 53 alias records"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group tasks register with"
  value       = aws_lb_target_group.app.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB's security group, for cross-referencing from ecs-task-sg"
  value       = aws_security_group.alb.id
}