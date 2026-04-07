# Project Setup Summary

## Overview

This project implements a production-ready microservices architecture on AWS with **Infrastructure as Code (IaC)** using Terraform. The solution includes:

- **3 Java Microservices** deployed to AWS ECS Fargate
- **Multi-tier networking** with VPC, public/private subnets
- **Database**: RDS Aurora MySQL cluster with encryption
- **Container Registry**: ECR with lifecycle policies
- **Load Balancing**: ALB with path-based routing
- **DNS**: Route53 with custom domain support
- **Security**: Secrets Manager for credentials, IAM roles
- **Monitoring**: CloudWatch logs, metrics, alarms, dashboards
- **CI/CD**: GitHub Actions workflows for automated deployments
- **Local Development**: Docker Compose setup

## Quick Start

### 1. Prerequisites
```bash
# Install required tools
- AWS CLI v2
- Terraform >= 1.0
- Docker Desktop
- Apache Maven 3.8+
- Java 17 JDK
```

### 2. Configure AWS
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

### 3. Deploy Infrastructure
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Build & Deploy Services
```bash
./scripts/push-to-ecr.sh
```

### 5. Access Services
```bash
# Get ALB DNS
aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName'

# Test endpoints
curl http://<ALB-DNS>/service-auth/health
```

## Directory Structure Explained

### terraform/
Contains all infrastructure code organized by concerns:

- **modules/**: Reusable Terraform modules
  - `vpc/`: VPC, subnets, routing, security groups
  - `rds-aurora/`: Database cluster with high availability
  - `ecr/`: Container registries with lifecycle policies
  - `ecs-fargate/`: ECS cluster, services, auto-scaling
  - `alb/`: Application Load Balancer, target groups
  - `route53/`: DNS routing
  - `secrets-manager/`: Credential storage & rotation
  - `cloudwatch/`: Monitoring, logs, alarms, dashboards
  - `iam/`: IAM roles and policies

- **environments/dev/**: Development environment configuration
  - `main.tf`: Orchestrates all modules
  - `variables.tf`: Input variables with defaults
  - `outputs.tf`: Output values for reference
  - `terraform.tfvars.example`: Example configuration file

### microservices/
3 independent Java Spring Boot microservices:

Each service includes:
- `pom.xml`: Maven dependencies (Spring Boot, MySQL, JWT, AWS SDK)
- `Dockerfile`: Multi-stage Docker build for small images
- `src/`: Java source code
- `resources/application.properties`: Configuration with environment variable substitution

Services:
- **service-auth**: Authentication & JWT token management
- **service-user**: User management & profiles
- **service-product**: Product catalog & management

All services connect to the same Aurora database and retrieve credentials from Secrets Manager.

### .github/workflows/
GitHub Actions CI/CD pipelines:

- `deploy-infrastructure.yml`: Terraform plan & apply
- `deploy-service-auth.yml`: Build, push to ECR, deploy
- `deploy-service-user.yml`: Build, push to ECR, deploy
- `deploy-service-product.yml`: Build, push to ECR, deploy

Triggers: Push to main or develop branches

### scripts/
Helper scripts for common operations:

- `setup.sh`: Complete project initialization
- `push-to-ecr.sh`: Build and push Docker images
- `get-outputs.sh`: Retrieve Terraform outputs

### Configuration Files

- `docker-compose.yml`: Local development with MySQL, services, NGINX
- `nginx.conf`: NGINX reverse proxy configuration
- `DEPLOYMENT_GUIDE.md`: Step-by-step deployment instructions
- `GITHUB_ACTIONS_SETUP.md`: GitHub Actions secrets configuration
- `README.md`: Project documentation

## AWS Resources Created

### Networking
- VPC (10.0.0.0/16)
- 2 Public Subnets (ALB)
- 2 Private Subnets (ECS tasks)
- 2 Database Subnets (RDS)
- NAT Gateways for private subnet internet access
- Route tables and routing rules

### Database
- RDS Aurora MySQL cluster (2 instances)
- Automated daily backups (30 days retention)
- Encryption at rest with KMS
- Enhanced monitoring via CloudWatch

### Container Registry
- 3 ECR repositories (one per service)
- KMS encryption enabled
- Lifecycle policy (keep 10 latest images)
- Vulnerability scanning on push

### Compute
- ECS Fargate cluster
- Task definitions for each service
- 2 tasks per service (desired count)
- Auto-scaling (1-4 tasks based on CPU/Memory)

### Load Balancing & DNS
- Application Load Balancer in public subnets
- Target groups with health checks
- Path-based routing (/service-auth, etc.)
- Route53 records (A and wildcard)
- HTTP redirect to HTTPS (if certificate provided)

### Security
- Security groups with least-privilege rules
- IAM roles for ECS tasks
- Secrets Manager for DB credentials
- KMS keys for encryption (ECR, RDS, EBS)

### Monitoring
- CloudWatch Log Groups (/ecs/microservices-app/*)
- Metrics for CPU, Memory, ALB response time
- Alarms for unhealthy hosts, high response time
- Composite alarms, Dashboard, SNS notifications

## Deployment Flow

```
Git Push
  ↓
GitHub Actions triggered
  ↓
Build Docker image
  ↓
Push to ECR
  ↓
Update ECS task definition
  ↓
Update ECS service
  ↓
ECS updates tasks (blue-green)
  ↓
ALB health checks pass
  ↓
Service available
```

## Customization

### Add New Microservice

1. Create `microservices/service-name/`
2. Add Docker build and source files
3. Create `.github/workflows/deploy-service-name.yml`
4. Add service to `terraform/environments/dev/variables.tf`
5. Deploy via `terraform apply`

### Change Database

In `terraform/modules/rds-aurora/main.tf`, change engine:
- From: `engine = "aurora-mysql"`
- To: `engine = "aurora-postgresql"`

### Add SSL Certificate

1. Request ACM certificate in AWS Console
2. Update `terraform.tfvars`:
   ```hcl
   ssl_certificate_arn = "arn:aws:acm:..."
   ```
3. Re-apply Terraform

### Scale Services

Modify in `terraform/environments/dev/variables.tf`:
```hcl
ecs_desired_count = 3  # Start with 3 tasks
ecs_max_capacity  = 8  # Scale up to 8 tasks
```

## Cost Estimation (Monthly - Dev)

- ALB: ~$16
- ECS Fargate: ~$30-50 (2 tasks × 256 CPU)
- RDS Aurora: ~$50-100 (db.t3.small × 2)
- Data Transfer: ~$5-10
- CloudWatch: ~$5-10

**Total**: ~$100-175/month for dev environment

## Security Best Practices Implemented

1. ✅ Private subnets for ECS (no direct internet)
2. ✅ Database in private subnets (not publicly accessible)
3. ✅ Secrets stored in Secrets Manager (not in code)
4. ✅ IAM roles with least privilege
5. ✅ KMS encryption for data at rest
6. ✅ ALB only accepts HTTP/HTTPS
7. ✅ ECS tasks run as non-root user
8. ✅ Security group ingress restricted
9. ✅ CloudWatch logs encrypted
10. ✅ GitHub Actions uses IAM role (no long-term keys)

## Monitoring & Troubleshooting

### View Logs
```bash
aws logs tail /ecs/microservices-app/service-auth --follow
```

### Check Service Status
```bash
aws ecs describe-services \
  --cluster microservices-app-cluster \
  --services service-auth-service
```

### Monitor Database
```bash
aws rds describe-db-clusters
```

### View CloudWatch Dashboard
```bash
aws cloudwatch describe-dashboards
```

## Next Steps

1. Add data persistence (RDS schema)
2. Implement service-to-service communication
3. Add API Gateway for external access
4. Set up secrets rotation Lambda
5. Implement distributed tracing (X-Ray)
6. Add load testing
7. Prod environment with multi-region
8. Blue-green deployments
9. Canary deployments with CodeDeploy

## Support & Troubleshooting

See `DEPLOYMENT_GUIDE.md` for:
- Step-by-step deployment instructions
- Troubleshooting common issues
- Architecture diagrams
- Best practices

See `GITHUB_ACTIONS_SETUP.md` for:
- GitHub Actions secrets configuration
- OIDC setup with GitHub
- Workflow troubleshooting

---

**Architecture**: Microservices on ECS Fargate
**Infrastructure**: Terraform (IaC)
**CI/CD**: GitHub Actions
**Database**: RDS Aurora
**Monitoring**: CloudWatch
**Version**: 1.0.0
