variable "repository_names" {
  type        = list(string)
  description = "Names of the ECR repositories to create"
}

variable "max_image_count" {
  type        = number
  description = "Maximum number of tagged images to retain per repository before older ones expire"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all repositories created by this module"
  default     = {}
}