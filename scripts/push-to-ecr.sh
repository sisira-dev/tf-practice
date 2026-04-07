#!/bin/bash

# Script to build and push Docker images to ECR

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}

echo "Building and pushing Docker images to ECR..."
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"

# Services to build
SERVICES=("service-auth" "service-user" "service-product")

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push each service
for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "=== Building $SERVICE ==="

    IMAGE_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/microservices-app-$SERVICE"

    # Build image
    docker build -t "$IMAGE_URL:latest" "microservices/$SERVICE"

    # Tag with commit hash
    COMMIT_HASH=$(git rev-parse --short HEAD)
    docker tag "$IMAGE_URL:latest" "$IMAGE_URL:$COMMIT_HASH"

    # Push images
    echo "Pushing $SERVICE to ECR..."
    docker push "$IMAGE_URL:latest"
    docker push "$IMAGE_URL:$COMMIT_HASH"

    echo "✓ $SERVICE pushed successfully"
done

echo ""
echo "✓ All images pushed to ECR"
