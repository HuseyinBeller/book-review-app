#!/bin/bash

# Book Review App - EKS Infrastructure Deployment Script

set -e

echo "🚀 Book Review App - EKS Infrastructure Deployment"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl is not installed. You'll need it after deployment.${NC}"
fi

# Check AWS credentials
echo -e "${YELLOW}🔍 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials found${NC}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}📝 Creating terraform.tfvars from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${YELLOW}⚠️  Please edit terraform.tfvars with your preferred settings before proceeding.${NC}"
    echo -e "${YELLOW}   Press any key to continue after editing, or Ctrl+C to exit...${NC}"
    read -n 1 -s
fi

# Initialize Terraform
echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "${YELLOW}✅ Validating Terraform configuration...${NC}"
terraform validate

# Plan deployment
echo -e "${YELLOW}📋 Creating deployment plan...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "${YELLOW}❓ Do you want to apply this plan? (y/N)${NC}"
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelled.${NC}"
    exit 1
fi

# Apply the plan
echo -e "${GREEN}🚀 Deploying infrastructure...${NC}"
terraform apply tfplan

# Get outputs
echo -e "${GREEN}📊 Deployment completed! Getting outputs...${NC}"
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw vpc_id | cut -d':' -f4)

# Configure kubectl
echo -e "${YELLOW}⚙️  Configuring kubectl...${NC}"
if command -v kubectl &> /dev/null; then
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    echo -e "${GREEN}✅ kubectl configured successfully${NC}"
else
    echo -e "${YELLOW}⚠️  kubectl not found. Install it and run:${NC}"
    echo "   aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME"
fi

# Display important information
echo -e "${GREEN}"
echo "🎉 Infrastructure deployment completed successfully!"
echo "================================================"
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo ""
echo "Next steps:"
echo "1. Verify cluster access: kubectl get nodes"
echo "2. Create namespace: kubectl create namespace book-review"
echo "3. Deploy your application: kubectl apply -f ../book-review-app/k8s/ -n book-review"
echo "4. Deploy ALB ingress: kubectl apply -f examples/book-review-ingress.yaml"
echo "5. Get ALB URL: kubectl get ingress book-review-ingress -n book-review"
echo "6. Check load balancer controller: kubectl get pods -n kube-system | grep aws-load-balancer-controller"
echo -e "${NC}"

# Clean up
rm -f tfplan 