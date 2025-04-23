terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "devops-template-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  environment = "prod"
  vpc_cidr    = "10.2.0.0/16"

  public_subnet_cidrs = [
    "10.2.1.0/24",
    "10.2.2.0/24",
    "10.2.3.0/24"
  ]

  private_subnet_cidrs = [
    "10.2.4.0/24",
    "10.2.5.0/24",
    "10.2.6.0/24"
  ]

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}

module "ecs" {
  source = "../../modules/ecs"

  environment           = "prod"
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  aws_region           = var.aws_region
  container_name       = "app"
  container_image      = "nginx:latest"
  container_port       = 80
  desired_count        = 3
  task_cpu             = 1024
  task_memory          = 2048
  log_retention_days   = 30

  # These would typically come from an ALB module
  alb_security_group_id = aws_security_group.alb.id
  target_group_arn      = aws_lb_target_group.main.arn
}

# ALB Resources
resource "aws_security_group" "alb" {
  name        = "prod-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = true

  tags = {
    Environment = "prod"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "prod-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
} 