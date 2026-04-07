#!/bin/bash

# Script to retrieve deployment information

set -e

ENVIRONMENT=${1:-dev}

echo "=== Deployment Information for $ENVIRONMENT Environment ==="
echo ""

cd terraform/environments/$ENVIRONMENT

echo "Getting Terraform outputs..."
echo ""

# Get ALB DNS Name
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "ALB DNS Name: $ALB_DNS"
echo ""

# Get Domain Name
DOMAIN_NAME=$(terraform output -raw domain_name)
echo "Domain Name: $DOMAIN_NAME"
echo ""

# Get ECR Repositories
echo "ECR Repositories:"
terraform output -json ecr_repositories | jq 'to_entries[] | "\(.key): \(.value)"'
echo ""

# Get ECS Clusters
echo "ECS Clusters:"
terraform output -json ecs_cluster_name | jq 'to_entries[] | "\(.key): \(.value)"'
echo ""

# Get Database Endpoint
DB_ENDPOINT=$(terraform output -raw database_endpoint)
echo "Database Endpoint: $DB_ENDPOINT (hidden for security)"
echo ""

# Get CloudWatch Dashboard
echo "CloudWatch Dashboard:"
terraform output -raw cloudwatch_dashboard_url
echo ""

# Get GitHub Actions Role
echo "GitHub Actions Role ARN:"
terraform output -raw github_actions_role_arn
echo ""

echo "=== Service Access URLs ==="
echo "Service Auth:    http://$ALB_DNS/service-auth/health"
echo "Service User:    http://$ALB_DNS/service-user/health"
echo "Service Product: http://$ALB_DNS/service-product/health"
