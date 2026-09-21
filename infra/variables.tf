variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "ecs-code-server"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "AWS region used for the deployment"
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block used by the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks used by the public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "image_tag" {
  type        = string
  description = "Git commit SHA tag to deploy for both container images"
}

variable "code_server_password" {
  type        = string
  description = "Password for code-server authentication"
  sensitive   = true
}