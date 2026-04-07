# Microservices Application - AWS Deployment with Terraform

Complete Infrastructure-as-Code solution for deploying 3 Java microservices on AWS using ECS Fargate, RDS Aurora, ECR, ALB, Route53, Secrets Manager, and CloudWatch monitoring.

## Architecture Overview

```
Internet
   ↓
Route 53 (DNS)
   ↓
ALB (Application Load Balancer)
   ↓
ECS Fargate Services
├── service-auth
├── service-user
└── service-product
   ↓
RDS Aurora (MySQL)
   ↓
Secrets Manager (DB Credentials)
   ↓
CloudWatch (Monitoring & Logging)
```

## Prerequisites

- AWS Account with appropriate IAM permissions
- Terraform >= 1.0
- Docker and Docker Compose
- Maven 3.8+
- Java 17 JDK
- Git
- GitHub Account (for Actions workflow)

## Project Structure

```
tf1/
├── terraform/
│   ├── modules/
│   │   ├── vpc/                 # VPC, subnets, security groups
│   │   ├── rds-aurora/          # RDS Aurora cluster
│   │   ├── ecr/                 # ECR repositories
│   │   ├── ecs-fargate/         # ECS cluster, services, tasks
│   │   ├── alb/                 # ALB and target groups
│   │   ├── route53/             # Route53 DNS
│   │   ├── secrets-manager/     # Secrets management
│   │   ├── cloudwatch/          # CloudWatch monitoring
│   │   └── iam/                 # IAM roles and policies
│   └── environments/
│       └── dev/                 # Development environment
├── microservices/
│   ├── service-auth/            # Authentication service
│   ├── service-user/            # User management service
│   └── service-product/         # Product management service
├── .github/
│   └── workflows/               # GitHub Actions CI/CD
└── scripts/                     # Helper scripts
```

## Getting Started

### 1. Set Up AWS Credentials

Configure your AWS credentials:

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

Or using environment variables:

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

### 2. Configure GitHub Actions

1. Go to your GitHub repository Settings
2. Navigate to Secrets and variables → Actions
3. Add the following secrets:
   - `AWS_ACCOUNT_ID`: Your AWS account ID
   - `AWS_ROLE_ARN`: ARN of the GitHub Actions IAM role

### 3. Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

### 4. Update Variables

Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
aws_region                = "us-east-1"
project_name              = "microservices-app"
environment               = "dev"
domain_name               = "your-domain.com"
db_master_username        = "admin"
db_master_password        = "YourSecurePassword123!"
sns_email                 = "your-email@example.com"
```

### 5. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

### 6. Apply Infrastructure

```bash
terraform apply tfplan
```

## Building and Running Locally

### Build Microservices

```bash
# Build all services
cd microservices/service-auth && mvn clean package
cd ../service-user && mvn clean package
cd ../service-product && mvn clean package
```

### Build Docker Images

```bash
# Build authentication service
cd microservices/service-auth
docker build -t microservices-app/service-auth:latest .

# Build user service
cd ../service-user
docker build -t microservices-app/service-user:latest .

# Build product service
cd ../service-product
docker build -t microservices-app/service-product:latest .
```

### Run with Docker Compose (Local Development)

```bash
docker-compose up -d
```

## Deploying to AWS

### Manual Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag and push image
docker tag microservices-app/service-auth:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/microservices-app-service-auth:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/microservices-app-service-auth:latest
```

### Automatic Deployment via GitHub Actions

1. Push changes to `main` branch
2. GitHub Actions automatically:
   - Builds the Docker image
   - Pushes to ECR
   - Updates the ECS service
   - Deploys the new version

## Configuration

### Environment Variables

Each microservice reads the following environment variables:

```
SERVICE_NAME=service-auth
ENVIRONMENT=dev
DATABASE_HOST=<aurora-endpoint>
DATABASE_PORT=3306
DATABASE_NAME=appdb
DATABASE_USERNAME=<fetched from Secrets Manager>
DATABASE_PASSWORD=<fetched from Secrets Manager>
```

### Database Credentials

Database credentials are stored in AWS Secrets Manager with automatic rotation enabled. To rotate manually:

```bash
aws secretsmanager rotate-secret \
  --secret-id db/credentials-xxx \
  --rotation-rules AutomaticallyAfterDays=30
```

## Monitoring

### CloudWatch Dashboard

Access the CloudWatch dashboard:

```bash
aws cloudwatch describe-dashboards --query 'DashboardEntries[].DashboardName'
```

### CloudWatch Logs

```bash
# View logs for service-auth
aws logs tail /ecs/microservices-app/service-auth --follow
```

### ECS Monitoring

```bash
# List ECS tasks
aws ecs list-tasks --cluster microservices-app-cluster

# Describe task details
aws ecs describe-tasks --cluster microservices-app-cluster --tasks <task-arn>
```

## ALB and Routing

### Access Services via ALB

- **Service Auth**: `http://<alb-dns>/service-auth/health`
- **Service User**: `http://<alb-dns>/service-user/health`
- **Service Product**: `http://<alb-dns>/service-product/health`

### Custom Domain Setup

Update Route53 DNS records to point to the ALB:

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://change-batch.json
```

## Scaling

### Auto-Scaling Policies

Services automatically scale based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Min instances: 1
- Max instances: 4

### Manual Scaling

```bash
aws ecs update-service \
  --cluster microservices-app-cluster \
  --service service-auth-service \
  --desired-count 3
```

## Maintenance

### Update Infrastructure

```bash
cd terraform/environments/dev
terraform plan
terraform apply
```

### Clean Up Resources

```bash
cd terraform/environments/dev
terraform destroy
```

## Security Best Practices

1. **ALB**: Only HTTP/HTTPS traffic
2. **ECS**: Tasks run in private subnets
3. **Database**: Encrypted Aurora cluster with IAM authentication
4. **Secrets**: All credentials stored in AWS Secrets Manager
5. **Logging**: CloudWatch Logs with encryption
6. **IAM**: Least privilege roles

## Troubleshooting

### Failed Deployment

Check ECS task logs:

```bash
aws logs tail /ecs/microservices-app/service-auth --follow
```

### Database Connection Issues

Verify security group rules and database status:

```bash
aws rds describe-db-clusters --query 'DBClusters[0].[DBClusterIdentifier,Status]'
```

### ALB Health Checks

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## Cost Optimization

- Use ECS Fargate (pay per request)
- Aurora Serverless for variable workloads
- CloudWatch log retention set to 7 days
- Reserve RDS instances for production

## Documentation Links

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/best_practices.html)
- [RDS Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [GitHub Actions for AWS](https://github.com/aws-actions)

## Support

For issues and questions, refer to:
- AWS Documentation
- Terraform Registry
- GitHub Actions Documentation

## License

MIT License

---

**Last Updated**: April 2026
