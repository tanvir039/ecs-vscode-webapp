locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "Tanvir"
  }
}


module "vpc" {
  source = "./modules/vpc"

  name                = local.name
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs

  tags = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_names = ["code-server-app", "nginx-sidecar"]
  tags             = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  tags = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  depends_on = [module.alb]

  name              = local.name
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_group_arn  = module.alb.target_group_arn

  nginx_image_url         = module.ecr.repository_urls["nginx-sidecar"]
  code_server_image_url   = module.ecr.repository_urls["code-server-app"]
  image_tag               = var.image_tag
  code_server_secret_name = "ecs-code-server-app/code-server-password"

  tags = local.common_tags
}


resource "aws_vpc_security_group_ingress_rule" "task_from_alb" {
  description = "Allow inbound from the ALB to nginx on 8081"

  security_group_id            = module.ecs.ecs_task_security_group_id
  referenced_security_group_id = module.alb.alb_security_group_id
  from_port                    = 8081
  to_port                      = 8081
  ip_protocol                  = "tcp"

  tags = local.common_tags
}


resource "aws_vpc_security_group_egress_rule" "alb_to_task" {
  description = "Allow outbound from the ALB to the ECS task on 8081"

  security_group_id            = module.alb.alb_security_group_id
  referenced_security_group_id = module.ecs.ecs_task_security_group_id
  from_port                    = 8081
  to_port                      = 8081
  ip_protocol                  = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "task_egress_all" {
  description = "Allow all outbound (ECR pulls, AWS API calls, etc.)"

  security_group_id = module.ecs.ecs_task_security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = module.alb.alb_security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  description = "Allow inbound HTTP from the internet"
  tags        = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = module.alb.alb_security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  description = "Allow inbound HTTPS from the internet"
  tags        = local.common_tags
}


module "dns" {
  source = "./modules/dns"

  domain_name  = "tm.tanvirahmed.uk"
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "acm" {
  source = "./modules/acm"

  domain_name    = "tm.tanvirahmed.uk"
  hosted_zone_id = module.dns.hosted_zone_id
  tags           = local.common_tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.alb_arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = module.acm.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arn
  }

  tags = local.common_tags
}
