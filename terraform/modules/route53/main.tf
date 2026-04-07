# Route53 Module - DNS routing

variable "domain_name" {
  description = "Domain name for Route 53"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB Zone ID"
  type        = string
}

variable "create_route53_zone" {
  description = "Create Route 53 zone"
  type        = bool
  default     = false
}

# Route 53 Zone (optional - if you own the domain)
resource "aws_route53_zone" "main" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Environment = var.environment
  }
}

# A Record pointing to ALB
resource "aws_route53_record" "alb" {
  zone_id = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Wildcard Record for subdomain routing
resource "aws_route53_record" "wildcard" {
  zone_id = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  name    = "*.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Data source for existing Route 53 zone
data "aws_route53_zone" "existing" {
  count = var.create_route53_zone ? 0 : 1
  name  = var.domain_name
}

output "zone_id" {
  description = "Route 53 Zone ID"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

output "nameservers" {
  description = "Route 53 nameservers"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].name_servers : data.aws_route53_zone.existing[0].name_servers
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}
