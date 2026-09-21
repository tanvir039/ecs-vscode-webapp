variable "name" {
  type        = string
  description = "Name prefix used for the VPC and its resources"
}

variable "region" {
  type        = string
  description = "AWS region to deploy into"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets, one per AZ"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources in this module"
  default     = {}
}