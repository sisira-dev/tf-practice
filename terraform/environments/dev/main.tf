# Main Terraform configuration for dev environment
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "development/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}

# RDS Aurora Module
module "rds_aurora" {
  source = "../../modules/rds-aurora"

  project_name       = var.project_name
  environment        = var.environment
  db_subnet_group_name = module.vpc.db_subnet_group_name
  rds_security_group_id = module.vpc.rds_security_group_id
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  instance_class     = var.db_instance_class
  instance_count     = var.db_instance_count
  skip_final_snapshot = var.skip_final_snapshot
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name           = var.project_name
  environment            = var.environment
  alb_security_group_id  = module.vpc.alb_security_group_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  vpc_id                 = module.vpc.vpc_id
  services               = var.services
  container_port         = var.container_port
  ssl_certificate_arn    = var.ssl_certificate_arn
  health_check_path      = var.health_check_path
  health_check_matcher   = var.health_check_matcher
}

# Route53 Module
module "route53" {
  source = "../../modules/route53"

  domain_name            = var.domain_name
  environment            = var.environment
  alb_dns_name           = module.alb.alb_dns_name
  alb_zone_id            = module.alb.alb_zone_id
  create_route53_zone    = var.create_route53_zone
}

# ECR Repositories for each service
module "ecr" {
  for_each = toset(var.services)

  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  service_name = each.value
}

# Secrets Manager for each service
module "secrets" {
  for_each = toset(var.services)

  source = "../../modules/secrets-manager"

  environment           = var.environment
  application_name      = each.value
  database_username     = var.db_master_username
  database_password     = var.db_master_password
  database_host         = module.rds_aurora.cluster_endpoint
  database_port         = 3306
  database_name         = var.db_name
  enable_rotation       = var.enable_secret_rotation
  rotation_days         = 30
  aws_region            = var.aws_region
  api_keys              = var.api_keys
}

# ECS Services for each microservice
module "ecs_fargate" {
  for_each = toset(var.services)

  source = "../../modules/ecs-fargate"

  project_name           = var.project_name
  environment            = var.environment
  service_name           = each.value
  container_image        = "${module.ecr[each.value].repository_url}:latest"
  container_port         = var.container_port
  task_cpu               = var.task_cpu
  task_memory            = var.task_memory
  private_subnet_ids     = module.vpc.private_subnet_ids
  ecs_security_group_id  = module.vpc.ecs_security_group_id
  target_group_arn       = module.alb.target_group_arns[each.value]
  alb_listener           = module.alb.listener_arn
  database_host          = module.rds_aurora.cluster_endpoint
  database_port          = 3306
  database_name          = var.db_name
  secrets_manager_arn    = module.secrets[each.value].db_credentials_secret_arn
  aws_region             = var.aws_region
  min_capacity           = var.ecs_min_capacity
  max_capacity           = var.ecs_max_capacity
  desired_count          = var.ecs_desired_count
  cpu_target_percentage  = 70
  memory_target_percentage = 80
}

# CloudWatch Module
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name      = var.project_name
  environment       = var.environment
  log_retention_days = var.log_retention_days
  sns_email         = var.sns_email
  alb_name          = module.alb.alb_arn
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}
