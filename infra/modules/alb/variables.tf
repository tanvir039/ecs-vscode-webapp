variable "name" {
  type        = string
  description = "Name prefix used for the ALB resources"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which the ALB will be created"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of the public subnets used by the ALB"

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "The ALB requires at least two public subnets."
  }
}

variable "target_port" {
  type        = number
  description = "Port the target group forwards traffic to on each task"
  default     = 8081
}

variable "health_check_path" {
  type        = string
  description = "Path the target group health check requests"
  default     = "/health"
}

variable "idle_timeout" {
  type        = number
  description = "ALB connection idle timeout in seconds; must exceed nginx's proxy_read_timeout/proxy_send_timeout"
  default     = 3600
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to ALB resources"
  default     = {}
}