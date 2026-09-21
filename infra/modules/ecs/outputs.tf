output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group used by ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "ecs_task_security_group_id" {
  description = "ID of the ECS task security group, for cross-referencing from alb-sg"
  value       = aws_security_group.ecs_task.id
}