#!/bin/bash

# Book Review App - EKS Infrastructure Cleanup Script

set -e

echo "🗑️  Book Review App - EKS Infrastructure Cleanup"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Warning message
echo -e "${RED}"
echo "⚠️  WARNING: This will destroy ALL infrastructure resources!"
echo "   - EKS Cluster"
echo "   - VPC and all networking components"
echo "   - Security Groups"
echo "   - NAT Gateways"
echo "   - All data will be lost!"
echo -e "${NC}"

# Double confirmation
echo -e "${YELLOW}❓ Are you absolutely sure you want to proceed? (type 'yes' to confirm)${NC}"
read -r CONFIRMATION

if [ "$CONFIRMATION" != "yes" ]; then
    echo -e "${GREEN}✅ Cleanup cancelled. Your infrastructure is safe.${NC}"
    exit 0
fi

# Final confirmation
echo -e "${RED}❓ Last chance! Type 'DESTROY' to confirm destruction:${NC}"
read -r FINAL_CONFIRMATION

if [ "$FINAL_CONFIRMATION" != "DESTROY" ]; then
    echo -e "${GREEN}✅ Cleanup cancelled. Your infrastructure is safe.${NC}"
    exit 0
fi

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
    terraform init
fi

# Create destroy plan
echo -e "${YELLOW}📋 Creating destruction plan...${NC}"
terraform plan -destroy -out=destroyplan

# Apply destruction
echo -e "${RED}💥 Destroying infrastructure...${NC}"
terraform apply destroyplan

# Clean up local files
echo -e "${YELLOW}🧹 Cleaning up local files...${NC}"
rm -f destroyplan
rm -f *.pem
rm -f terraform.tfstate.backup

echo -e "${GREEN}"
echo "✅ Infrastructure destroyed successfully!"
echo "======================================="
echo "All AWS resources have been removed."
echo "Local state files have been cleaned up."
echo -e "${NC}" 