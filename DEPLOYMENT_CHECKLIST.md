# Deployment Checklist

## Pre-Deployment

- [ ] AWS Account created and billing enabled
- [ ] AWS Access Keys generated (IAM user)
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (v1.0+)
- [ ] Docker Desktop installed
- [ ] Maven 3.8+ installed
- [ ] Java 17 JDK installed
- [ ] Git installed and repository cloned

## AWS Preparation

- [ ] Review IAM permissions (need permissions for: VPC, RDS, ECS, ECR, ALB, Route53, CloudWatch, Secrets Manager, KMS, IAM)
- [ ] Decide on AWS region (default: us-east-1)
- [ ] Get AWS Account ID
- [ ] Create/verify domain in Route53 (if using custom domain)
- [ ] Request ACM certificate (if using HTTPS)

## Configuration

- [ ] Copy `terraform/environments/dev/terraform.tfvars.example` to `terraform/environments/dev/terraform.tfvars`
- [ ] Update `terraform.tfvars` with:
  - [ ] AWS Region
  - [ ] Project name
  - [ ] Database password (strong password!)
  - [ ] SNS email for alarms
  - [ ] Domain name
  - [ ] SSL certificate ARN (if available)
- [ ] Review all variable values in `terraform.tfvars`

## GitHub Actions Setup

- [ ] Create GitHub repository
- [ ] Go to Settings → Secrets and Variables → Actions
- [ ] Create secret: `AWS_ACCOUNT_ID` (your 12-digit account ID)
- [ ] Create secret: `AWS_ROLE_ARN` (get after Terraform apply)
- [ ] Push code to main branch
- [ ] Verify workflows appear in Actions tab

## Infrastructure Deployment

- [ ] Navigate to `terraform/environments/dev`
- [ ] Run `terraform init`
- [ ] Run `terraform plan` and review output
- [ ] Run `terraform apply tfplan`
- [ ] Wait 10-15 minutes for all resources to create
- [ ] Verify all resources created successfully
- [ ] Get outputs: `terraform output`

## Microservice Deployment

- [ ] Build all microservices: `mvn clean package -DskipTests`
- [ ] Get ECR login token: `aws ecr get-login-password --region us-east-1 | docker login ...`
- [ ] Run `./scripts/push-to-ecr.sh` to build and push Docker images
- [ ] Verify images in ECR console
- [ ] Update ECS services to trigger deployment

## Verification

- [ ] All ECR repositories contain images
- [ ] ECS cluster has all services running
- [ ] ALB has healthy targets (wait if needed)
- [ ] Database is accessible and initialized
- [ ] Secrets Manager has database credentials
- [ ] CloudWatch logs are being generated
- [ ] Route53 records are created
- [ ] Test service endpoints:
  - [ ] `curl http://<ALB-DNS>/service-auth/health`
  - [ ] `curl http://<ALB-DNS>/service-user/health`
  - [ ] `curl http://<ALB-DNS>/service-product/health`

## Monitoring Setup

- [ ] SNS email subscription confirmed (check email)
- [ ] CloudWatch alarms created
- [ ] CloudWatch dashboard accessible
- [ ] Logs visible in CloudWatch Logs
- [ ] Metrics appearing in CloudWatch

## Security Verification

- [ ] Database credentials stored in Secrets Manager (not in code)
- [ ] RDS encrypted with KMS
- [ ] ECR encrypted with KMS
- [ ] ECS tasks run in private subnets
- [ ] Security groups restrict traffic appropriately
- [ ] IAM roles have least privilege
- [ ] No hardcoded secrets in code/config

## Documentation & Knowledge Transfer

- [ ] README.md reviewed and understood
- [ ] DEPLOYMENT_GUIDE.md followed successfully
- [ ] GITHUB_ACTIONS_SETUP.md configured
- [ ] PROJECT_SETUP_SUMMARY.md reviewed
- [ ] Know how to:
  - [ ] View logs: `aws logs tail /ecs/microservices-app/service-xxx`
  - [ ] Check service status: `aws ecs describe-services`
  - [ ] Scale services: modify `terraform.tfvars` and reapply
  - [ ] Update code: push to GitHub → GitHub Actions handles deployment

## Backup & Disaster Recovery

- [ ] RDS backups configured (automated daily)
- [ ] Backup retention set to 30 days
- [ ] Document database restoration procedure
- [ ] Test backup restoration in test environment

## Post-Deployment Tasks

- [ ] Set up DNS records to point to ALB (if using custom domain)
- [ ] Configure SSL/TLS certificate (if using HTTPS)
- [ ] Set up additional monitoring/alerting as needed
- [ ] Train team on deployment procedures
- [ ] Update documentation with project-specific info
- [ ] Set up log aggregation (optional)
- [ ] Configure application-specific health checks
- [ ] Implement database schema migrations

## Ongoing Operations

### Weekly
- [ ] Review CloudWatch alarms and logs
- [ ] Check RDS backup completion
- [ ] Monitor costs in AWS Billing

### Monthly
- [ ] Review and update security groups
- [ ] Audit IAM permissions
- [ ] Review scaling metrics
- [ ] Plan infrastructure updates

### Quarterly
- [ ] Disaster recovery drill
- [ ] Performance review and optimization
- [ ] Security audit
- [ ] Cost analysis and optimization

## Troubleshooting Quick Links

| Issue | Command |
|-------|---------|
| View logs | `aws logs tail /ecs/microservices-app/service-NAME --follow` |
| Check task status | `aws ecs describe-tasks --cluster microservices-app-cluster --tasks TASK_ARN` |
| Restart service | `aws ecs update-service --cluster microservices-app-cluster --service NAME-service --force-new-deployment` |
| View database status | `aws rds describe-db-clusters --query 'DBClusters[0].[DBClusterIdentifier,Status]'` |
| Get ALB DNS | `aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName'` |
| Check ALB targets | `aws elbv2 describe-target-health --target-group-arn TG_ARN` |
| View CloudWatch alarms | `aws cloudwatch describe-alarms` |

## Sign-Off

- [ ] Project Lead: _________________ Date: _______
- [ ] Infrastructure Admin: _________________ Date: _______
- [ ] Security Review: _________________ Date: _______

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Version**: 1.0.0
