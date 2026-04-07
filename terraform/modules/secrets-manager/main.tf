# Secrets Manager Module - Database credentials and key rotation

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "db/credentials-"
  recovery_window_in_days = 7
  description             = "Database credentials for ${var.application_name}"

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
    engine   = "mysql"
    host     = var.database_host
    port     = var.database_port
    dbname   = var.database_name
  })
}

# Rotation function for Secrets Manager
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  count               = var.enable_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  rotation_lambda_arn = aws_lambda_function.rotation[0].arn

  depends_on = [aws_lambda_permission.rotation_permission[0]]
}

# Lambda function for rotation (basic placeholder)
resource "aws_lambda_function" "rotation" {
  count            = var.enable_rotation ? 1 : 0
  filename         = "lambda_rotation.zip"
  function_name    = "${var.application_name}-db-rotation"
  role             = aws_iam_role.lambda_rotation[0].arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 30
  
  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_rotation_policy[0]
  ]
}

# IAM role for Lambda rotation
resource "aws_iam_role" "lambda_rotation" {
  count              = var.enable_rotation ? 1 : 0
  name_prefix        = "${var.application_name}-lambda-rotation-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_rotation_policy" {
  count              = var.enable_rotation ? 1 : 0
  role               = aws_iam_role.lambda_rotation[0].name
  policy_arn         = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "rotation_permission" {
  count              = var.enable_rotation ? 1 : 0
  statement_id       = "AllowSecretsManagerInvoke"
  action             = "lambda:InvokeFunction"
  function_name      = aws_lambda_function.rotation[0].function_name
  principal          = "secretsmanager.amazonaws.com"
}

# Secret for API keys
resource "aws_secretsmanager_secret" "api_keys" {
  name_prefix             = "api/keys-"
  recovery_window_in_days = 7
  description             = "API keys for ${var.application_name}"

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id     = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode(var.api_keys)
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "application_name" {
  description = "Application name"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "database_host" {
  description = "Database host"
  type        = string
}

variable "database_port" {
  description = "Database port"
  type        = number
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "enable_rotation" {
  description = "Enable automatic rotation"
  type        = bool
  default     = true
}

variable "rotation_days" {
  description = "Rotate secret every N days"
  type        = number
  default     = 30
}

variable "api_keys" {
  description = "API keys to store"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

output "db_credentials_secret_arn" {
  description = "ARN of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_id" {
  description = "ID of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.id
}

output "api_keys_secret_arn" {
  description = "ARN of API keys secret"
  value       = aws_secretsmanager_secret.api_keys.arn
}
