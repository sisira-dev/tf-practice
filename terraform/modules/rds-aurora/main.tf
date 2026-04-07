# RDS Aurora Module - Database cluster with replication and monitoring

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.project_name}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = var.aurora_engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = var.db_subnet_group_name
  vpc_security_group_ids          = [var.rds_security_group_id]
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.aurora.arn
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "${var.project_name}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  enable_http_endpoint            = false
  enable_iam_database_authentication = true

  tags = {
    Name        = "${var.project_name}-aurora-cluster"
    Environment = var.environment
  }
}

# Aurora Instances
resource "aws_rds_cluster_instance" "aurora" {
  count              = var.instance_count
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.instance_class
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
  publicly_accessible = false
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  tags = {
    Name        = "${var.project_name}-aurora-instance-${count.index + 1}"
    Environment = var.environment
  }
}

# KMS Key for encryption
resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-aurora-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "aurora" {
  name          = "alias/${var.project_name}-aurora"
  target_key_id = aws_kms_key.aurora.key_id
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "${var.project_name}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Cluster Parameter Group for Aurora MySQL 8.0
resource "aws_rds_cluster_parameter_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-cluster-pg-"
  family      = "aurora-mysql8.0"
  description = "Cluster parameter group for ${var.project_name}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = {
    Name        = "${var.project_name}-aurora-cluster-pg"
    Environment = var.environment
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-pg-"
  family      = "aurora-mysql8.0"
  description = "DB parameter group for ${var.project_name}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name        = "${var.project_name}-aurora-pg"
    Environment = var.environment
  }
}
