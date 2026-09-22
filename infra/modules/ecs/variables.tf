variable "name" {
  type        = string
  description = "Name prefix used for ECS resources"
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain ECS container logs in CloudWatch"
  default     = 14
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to ECS resources"
  default     = {}
}

variable "enable_container_insights" {
  type        = bool
  description = "Whether to enable CloudWatch Container Insights for the cluster (incurs additional cost)"
  default     = false
}

variable "task_cpu" {
  type        = number
  description = "CPU units for the Fargate task (e.g. 1024 = 1 vCPU)"
  default     = 1024
}

variable "task_memory" {
  type        = number
  description = "Memory (MB) for the Fargate task"
  default     = 2048
}

variable "region" {
  type        = string
  description = "AWS region, used for CloudWatch log configuration"
}

variable "nginx_image_url" {
  type        = string
  description = "ECR repository URL for the nginx sidecar image, without tag"
}

variable "code_server_image_url" {
  type        = string
  description = "ECR repository URL for the code-server image, without tag"
}

variable "image_tag" {
  type        = string
  description = "Tag to deploy for both images (e.g. git commit SHA)"
}

# variable "code_server_password" {
#   type        = string
#   description = "Password for code-server authentication"
#   sensitive   = true
# }

variable "code_server_secret_name" {
  type        = string
  description = "Name of the existing Secrets Manager secret holding the code-server password"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the ECS tasks run in"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of the public subnets the ECS service places tasks into"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB target group the service registers with"
}

variable "desired_count" {
  type        = number
  description = "Number of tasks the service should keep running"
  default     = 1
}