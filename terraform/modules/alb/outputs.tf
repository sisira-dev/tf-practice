output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "ALB Zone ID for Route 53"
  value       = aws_lb.main.zone_id
}

output "target_group_arns" {
  description = "Target group ARNs"
  value       = { for k, v in aws_lb_target_group.main : k => v.arn }
}

output "listener_arn" {
  description = "Listener ARN"
  value       = local.listener_arn
}

output "alb_logs_bucket_id" {
  description = "ALB logs S3 bucket ID"
  value       = aws_s3_bucket.alb_logs.id
}
