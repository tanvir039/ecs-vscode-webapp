terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.name

  azs  = ["${var.region}a", "${var.region}b"]
  cidr = var.vpc_cidr

  public_subnets = var.public_subnet_cidrs

  create_igw              = true
  map_public_ip_on_launch = true

  enable_nat_gateway = false

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}
