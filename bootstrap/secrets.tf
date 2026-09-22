resource "aws_secretsmanager_secret" "code_server_password" {
  name = "ecs-code-server-app/code-server-password"
}

resource "aws_secretsmanager_secret_version" "code_server_password" {
  secret_id     = aws_secretsmanager_secret.code_server_password.id
  secret_string = var.code_server_password
}