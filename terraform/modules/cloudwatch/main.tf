# CloudWatch Module - Monitoring and logging

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 7
}

variable "sns_email" {
  description = "SNS email for alerts"
  type        = string
  default     = ""
}

variable "alb_name" {
  description = "ALB name"
  type        = string
  default     = ""
}

# SNS Topic for alarms
resource "aws_sns_topic" "alarms" {
  name_prefix = "${var.project_name}-alarms-"

  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.sns_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

# Alarm for ALB Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count               = var.alb_name != "" ? 1 : 0
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when ALB has unhealthy hosts"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_name
  }
}

# Alarm for ALB Target Response Time
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count               = var.alb_name != "" ? 1 : 0
  alarm_name          = "${var.project_name}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when ALB response time is high"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_name
  }
}

# Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average" }],
            ["AWS/ECS", "MemoryUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ECS Service Metrics"
        }
      }
    ]
  })
}

# Log Group for CloudWatch Insights
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/${var.project_name}/application"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
  }
}

# Composite Alarm for overall health
resource "aws_cloudwatch_composite_alarm" "application_health" {
  alarm_name          = "${var.project_name}-application-health"
  alarm_description   = "Composite alarm for application health"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alarms.arn]

  alarm_rule = var.alb_name != "" ? "ALARM(${aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.alb_response_time[0].alarm_name})" : "OK"
}

# Metric Math Alarm for ECS CPU
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  alarm_description   = "Alert when ECS CPU utilization is high"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  metric_query {
    id          = "e1"
    expression  = "AVG([m1])"
    label       = "Average CPU"
    return_data = true
  }

  metric_query {
    id      = "m1"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
    }
  }
}

data "aws_region" "current" {}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.application_logs.name
}
