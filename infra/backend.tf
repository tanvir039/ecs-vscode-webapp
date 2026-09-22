terraform {
  backend "s3" {
    bucket       = "ecs-code-server-tanvir-tfstate"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}