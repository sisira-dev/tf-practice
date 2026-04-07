# ECR Module - Elastic Container Registry for Docker images

resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-${var.service_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.service_name}-ecr"
    Environment = var.environment
    Service     = var.service_name
  }
}

# KMS Key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.service_name}-ecr-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${var.project_name}-${var.service_name}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}

# ECR Lifecycle Policy to clean up old images
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus             = "any"
          countType             = "imageCountMoreThan"
          countNumber           = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy for pulling images
resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSPull"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages"
        ]
      }
    ]
  })
}
