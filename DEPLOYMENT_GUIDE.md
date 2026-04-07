# Deployment Instructions

## Prerequisites

- AWS Account with billing enabled
- Terraform installed (v1.0+)
- AWS CLI configured with credentials
- Docker and Docker Desktop
- Maven 3.8+
- Java 17 JDK

## Step 1: Initial Setup

### 1.1 Clone and Configure

```bash
git clone <your-repo-url>
cd tf1

# Make scripts executable
chmod +x scripts/*.sh
```

### 1.2 Set Up AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

### 1.3 Create Terraform Variables File

```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars

# Edit the file with your values
nano terraform/environments/dev/terraform.tfvars
```

**Important**: Update these values:
- `db_master_password`: Strong password for RDS
- `sns_email`: Email for CloudWatch alarms
- `domain_name`: Your actual domain

## Step 2: Deploy Infrastructure

### 2.1 Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

### 2.2 Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the plan to ensure all resources are correct.

### 2.3 Apply Infrastructure

```bash
terraform apply tfplan
```

This creates:
- VPC with public, private, and database subnets
- EC2 Security Groups
- RDS Aurora cluster
- ALB with target groups
- ECS cluster
- ECR repositories
- Route53 records
- Secrets Manager entries
- CloudWatch logs and alarms
- IAM roles

**Wait for 10-15 minutes for all resources to be created.**

### 2.4 Get Infrastructure Outputs

```bash
./../../scripts/get-outputs.sh
```

Save the outputs, especially:
- ALB DNS Name
- ECR Repository URLs
- Database Endpoint
- GitHub Actions Role ARN

## Step 3: Build Microservices

### 3.1 Build Locally (Optional)

```bash
cd ../../..

# Build all services
mvn -f microservices/service-auth/pom.xml clean package -DskipTests
mvn -f microservices/service-user/pom.xml clean package -DskipTests
mvn -f microservices/service-product/pom.xml clean package -DskipTests
```

### 3.2 Build Docker Images

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build and push images
./scripts/push-to-ecr.sh
```

## Step 4: Configure GitHub Actions

### 4.1 Create GitHub Secrets

1. Go to GitHub Repository → Settings → Secrets and Variables → Actions
2. Create secrets:
   - `AWS_ACCOUNT_ID`: Your 12-digit AWS Account ID
   - `AWS_ROLE_ARN`: Role ARN from Step 2.4

### 4.2 Verify Workflows

Check `.github/workflows/` directory contains:
- `deploy-infrastructure.yml`
- `deploy-service-auth.yml`
- `deploy-service-user.yml`
- `deploy-service-product.yml`

## Step 5: First Deployment

### 5.1 Manual Initial Deployment

If GitHub Actions hasn't run yet, manually push images:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

docker build -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-app-service-auth:latest microservices/service-auth/
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-app-service-auth:latest

# Repeat for other services
```

### 5.2 Update ECS Services

```bash
aws ecs update-service \
  --cluster microservices-app-cluster \
  --service service-auth-service \
  --force-new-deployment
```

## Step 6: Verify Deployment

### 6.1 Check Service Status

```bash
# Get ALB DNS name
aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName' --output text

# Test endpoints
curl http://<ALB-DNS>/service-auth/health
curl http://<ALB-DNS>/service-user/health
curl http://<ALB-DNS>/service-product/health
```

### 6.2 Monitor Logs

```bash
# Stream logs
aws logs tail /ecs/microservices-app/service-auth --follow

# View CloudWatch dashboard
aws cloudwatch describe-dashboards --query 'DashboardEntries[].DashboardName'
```

## Step 7: Configure Custom Domain (Optional)

```bash
# Update Route53 record to point to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id <ZONE_ID> \
  --change-batch file://change-batch.json
```

## Troubleshooting

### Services won't start
```bash
# Check task definition
aws ecs describe-task-definition --task-definition service-auth:1

# Check logs
aws logs tail /ecs/microservices-app/service-auth --follow
```

### Database connection fails
```bash
# Verify security groups allow traffic
aws ec2 describe-security-groups --group-ids <sg-id>

# Check database status
aws rds describe-db-clusters --query 'DBClusters[0].Status'
```

### ALB health checks failing
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

## Cleanup

To destroy all AWS resources:

```bash
cd terraform/environments/dev
terraform destroy
```

**Warning**: This will delete all resources and data. Ensure backups are taken.

## Next Steps

1. Configure SSL certificate (ACM)
2. Set up monitoring alerts
3. Implement CI/CD pipeline updates
4. Add database migrations
5. Implement custom business logic in microservices
6. Set up auto-scaling policies
7. Configure RDS backup schedules
