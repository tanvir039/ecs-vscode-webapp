output "repository_urls" {
  description = "Map of repository name to its ECR repository URL"
  value       = { for name, repo in module.ecr : name => repo.repository_url }
}