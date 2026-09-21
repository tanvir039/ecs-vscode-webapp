output "github_ecr_push_role_arn" {
  value = aws_iam_role.github_ecr_push.arn
}

output "github_terraform_deploy_role_arn" {
  value = aws_iam_role.github_terraform_deploy.arn
}