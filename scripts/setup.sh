#!/bin/bash

# Setup script for AWS Microservices Infrastructure
# This script initializes the development environment and deploys infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== AWS Microservices Infrastructure Setup ===${NC}\n"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI not found. Please install it first.${NC}"
        exit 1
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform not found. Please install it first.${NC}"
        exit 1
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker not found. Please install it first.${NC}"
        exit 1
    fi

    # Check Maven
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}Maven not found. Please install it first.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All prerequisites installed${NC}\n"
}

# Configure AWS
configure_aws() {
    echo -e "${YELLOW}Configuring AWS...${NC}"

    read -p "Enter your AWS Region (default: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}

    read -p "Enter your AWS Account ID: " AWS_ACCOUNT_ID

    if [ -z "$AWS_ACCOUNT_ID" ]; then
        echo -e "${RED}AWS Account ID is required${NC}"
        exit 1
    fi

    export AWS_REGION
    export AWS_ACCOUNT_ID

    # Verify AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}AWS credentials not configured properly${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ AWS configured${NC}\n"
}

# Build microservices
build_microservices() {
    echo -e "${YELLOW}Building microservices...${NC}"

    for service in service-auth service-user service-product; do
        echo -e "${YELLOW}Building $service...${NC}"
        cd "microservices/$service"
        mvn clean package -DskipTests -q
        cd ../..
        echo -e "${GREEN}✓ $service built${NC}"
    done

    echo ""
}

# Initialize Terraform
init_terraform() {
    echo -e "${YELLOW}Initializing Terraform...${NC}"

    cd terraform/environments/dev
    terraform init
    cd ../../..

    echo -e "${GREEN}✓ Terraform initialized${NC}\n"
}

# Plan infrastructure
plan_infrastructure() {
    echo -e "${YELLOW}Planning infrastructure...${NC}"

    cd terraform/environments/dev
    terraform plan -out=tfplan
    cd ../../..

    echo -e "${GREEN}✓ Infrastructure plan created${NC}\n"
}

# Apply infrastructure
apply_infrastructure() {
    echo -e "${YELLOW}Applying infrastructure...${NC}"

    read -p "Do you want to apply the infrastructure? (yes/no): " APPROVE

    if [ "$APPROVE" == "yes" ]; then
        cd terraform/environments/dev
        terraform apply tfplan
        cd ../../..
        echo -e "${GREEN}✓ Infrastructure deployed${NC}\n"
    else
        echo -e "${YELLOW}Infrastructure deployment cancelled${NC}\n"
    fi
}

# Main execution
main() {
    check_prerequisites
    configure_aws
    build_microservices
    init_terraform
    plan_infrastructure
    apply_infrastructure

    echo -e "${GREEN}=== Setup Complete ===${NC}"
    echo -e "\nNext steps:"
    echo -e "1. Review the Terraform plan: terraform/environments/dev/tfplan"
    echo -e "2. Push microservice images to ECR"
    echo -e "3. Access your services via the ALB DNS name"
}

main "$@"
