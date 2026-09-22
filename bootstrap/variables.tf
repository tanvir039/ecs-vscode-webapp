variable "code_server_password" {
  description = "Password for code-server authentication, stored in Secrets Manager"
  type = string
  sensitive = true 
}