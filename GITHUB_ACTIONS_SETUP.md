# GitHub Actions Workflow Secrets Configuration

This document explains the secrets needed for GitHub Actions CI/CD workflows.

## Required Secrets

### 1. AWS_ACCESS_KEY_ID
- **Description**: Your AWS Access Key ID
- **Value**: Your AWS access key (e.g., AKIA...)

### 2. AWS_SECRET_ACCESS_KEY
- **Description**: Your AWS Secret Access Key
- **Value**: Your AWS secret key

### 3. AWS_ACCOUNT_ID
- **Description**: Your AWS Account ID
- **Value**: 12-digit AWS Account ID (e.g., 123456789012)
- **How to find**: 
  ```bash
  aws sts get-caller-identity --query Account --output text
  ```

## Setting Up Secrets

1. Go to GitHub Repository → Settings
2. Select "Secrets and variables" → "Actions" from left sidebar
3. Click "New repository secret"
4. Add each secret with its value

## Required Permissions for GitHub Actions Role

The `github-actions` role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    }
  ]
}
```

## Setting Up OIDC with GitHub

For more secure authentication without storing long-term credentials:

```bash
# Create OIDC provider
aws iam create-openid-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create role that trusts GitHub
aws iam create-role \
  --role-name github-actions \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:GITHUB_ORG/GITHUB_REPO:ref:refs/heads/main"
        }
      }
    }]
  }'
```

## Workflow Execution

Workflows automatically trigger on:

1. **Service-specific workflows**
   - Trigger when code in `microservices/<service>/` changes
   - Trigger when the workflow file itself changes

2. **Infrastructure workflow**
   - Trigger when code in `terraform/` changes
   - Only applies on main branch

## Monitoring Workflow Runs

In GitHub:
1. Go to Actions tab
2. Click on workflow name
3. View run logs
4. Check job details for errors

## Troubleshooting

### Workflow fails with "Invalid IAM role ARN"
- Verify AWS_ROLE_ARN secret is correct
- Check role exists and is accessible

### ECR push fails
- Verify AWS credentials
- Check ECR repository exists
- Verify user has ecr:GetAuthorizationToken permission

### ECS deployment fails
- Check service exists in cluster
- Verify task definition is compatible
- Check ECS service logs
