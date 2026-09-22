terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


module "ecr" {
  source                  = "terraform-aws-modules/ecr/aws"
  version                 = "2.4.0"
  for_each                = toset(var.repository_names)
  repository_force_delete = true

  repository_name                 = each.value
  repository_image_tag_mutability = "IMMUTABLE"
  repository_image_scan_on_push   = true

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images beyond the last ${var.max_image_count}"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = var.tags
}