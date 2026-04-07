# Variables for dev environment

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "microservices-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# RDS Variables
variable "db_master_username" {
  description = "Master username for Aurora"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_master_password" {
  description = "Master password for Aurora"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!@"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_instance_class" {
  description = "Instance class for Aurora"
  type        = string
  default     = "db.t3.small"
}

variable "db_instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 2
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = true
}

# ALB Variables
variable "services" {
  description = "List of microservices"
  type        = list(string)
  default     = ["service-auth", "service-user", "service-product"]
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN (leave empty for HTTP only)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "Health check HTTP matcher"
  type        = string
  default     = "200"
}

# Route53 Variables
variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "example-app.com"
}

variable "create_route53_zone" {
  description = "Create Route53 zone"
  type        = bool
  default     = false
}

# ECS Variables
variable "task_cpu" {
  description = "Task CPU units"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Minimum capacity for auto-scaling"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum capacity for auto-scaling"
  type        = number
  default     = 4
}

# CloudWatch Variables
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "sns_email" {
  description = "SNS email for alerts"
  type        = string
  default     = ""
}

# Secrets Manager Variables
variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "api_keys" {
  description = "API keys to store in Secrets Manager"
  type        = map(string)
  default     = {}
  sensitive   = true
}
