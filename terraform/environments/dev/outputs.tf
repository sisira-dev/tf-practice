# Outputs for dev environment

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "domain_name" {
  description = "Domain name"
  value       = module.route53.domain_name
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = { for k, v in module.ecr : k => v.repository_url }
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = { for k, v in module.ecs_fargate : k => v.cluster_name }
}

output "database_endpoint" {
  description = "Aurora cluster endpoint"
  value       = module.rds_aurora.cluster_endpoint
  sensitive   = true
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.cloudwatch.dashboard_url
}

output "sns_topic_arn" {
  description = "SNS topic for alarms"
  value       = module.cloudwatch.sns_topic_arn
}

output "github_actions_role_arn" {
  description = "ARN for GitHub Actions IAM role"
  value       = module.iam.github_actions_role_arn
}
