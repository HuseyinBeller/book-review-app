#!/bin/bash

# Enhanced EKS Infrastructure Cleanup Script
# Handles all dependencies properly to avoid destroy issues

set -e

echo "🗑️  Enhanced EKS Infrastructure Cleanup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    echo "Please install kubectl to proceed with cleanup"
    exit 1
fi

# Check if we can connect to the cluster
echo -e "${BLUE}🔍 Checking cluster connectivity...${NC}"
if ! kubectl get nodes &> /dev/null; then
    echo -e "${YELLOW}⚠️  Cannot connect to EKS cluster. Proceeding with Terraform destroy only.${NC}"
    CLUSTER_ACCESSIBLE=false
else
    echo -e "${GREEN}✅ Connected to EKS cluster${NC}"
    CLUSTER_ACCESSIBLE=true
fi

# Warning message
echo -e "${RED}"
echo "⚠️  WARNING: This will destroy ALL infrastructure resources!"
echo "   📊 Current resources to be cleaned:"
if [ "$CLUSTER_ACCESSIBLE" = true ]; then
    echo "   - ArgoCD Applications and Resources"
    echo "   - Kubernetes Ingresses (ALBs)"
    echo "   - Persistent Volume Claims (EBS volumes)"
    echo "   - All Kubernetes workloads"
fi
echo "   - EKS Cluster and Node Groups"
echo "   - VPC and all networking components"
echo "   - Security Groups and Load Balancers"
echo "   - NAT Gateways and Elastic IPs"
echo "   🚨 ALL DATA WILL BE LOST!"
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

# Phase 1: Clean up Kubernetes resources (if cluster is accessible)
if [ "$CLUSTER_ACCESSIBLE" = true ]; then
    echo -e "${BLUE}"
    echo "🧹 Phase 1: Cleaning up Kubernetes resources..."
    echo "==============================================="
    echo -e "${NC}"

    # Step 1: Delete ArgoCD Applications (this removes all app resources)
    echo -e "${YELLOW}🎯 Deleting ArgoCD Applications...${NC}"
    if kubectl get applications -n argocd &> /dev/null; then
        kubectl delete applications --all -n argocd --timeout=300s || true
        echo "✅ ArgoCD applications deleted"
    else
        echo "ℹ️  No ArgoCD applications found"
    fi

    # Step 2: Force delete any remaining ingresses (ALBs)
    echo -e "${YELLOW}🌐 Deleting Ingresses (ALBs)...${NC}"
    if kubectl get ingress --all-namespaces &> /dev/null; then
        kubectl delete ingress --all --all-namespaces --timeout=300s || true
        echo "✅ All ingresses deleted"
    else
        echo "ℹ️  No ingresses found"
    fi

    # Step 3: Delete persistent volume claims (EBS volumes)
    echo -e "${YELLOW}💾 Deleting Persistent Volume Claims...${NC}"
    if kubectl get pvc --all-namespaces &> /dev/null; then
        kubectl delete pvc --all --all-namespaces --timeout=300s || true
        echo "✅ All PVCs deleted"
    else
        echo "ℹ️  No PVCs found"
    fi

    # Step 4: Delete services with LoadBalancer type
    echo -e "${YELLOW}⚖️ Deleting LoadBalancer services...${NC}"
    if kubectl get services --all-namespaces -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].metadata.name}' | grep -q .; then
        kubectl delete services --all-namespaces --field-selector spec.type=LoadBalancer --timeout=300s || true
        echo "✅ LoadBalancer services deleted"
    else
        echo "ℹ️  No LoadBalancer services found"
    fi

    # Step 5: Wait for ALB cleanup (important!)
    echo -e "${YELLOW}⏳ Waiting for AWS Load Balancers to be cleaned up...${NC}"
    sleep 60
    echo "✅ Cleanup wait completed"

    # Step 6: Scale down ArgoCD to prevent recreation
    echo -e "${YELLOW}📉 Scaling down ArgoCD...${NC}"
    kubectl scale deployment --all -n argocd --replicas=0 --timeout=120s || true
    kubectl scale statefulset --all -n argocd --replicas=0 --timeout=120s || true
    echo "✅ ArgoCD scaled down"

    echo -e "${GREEN}✅ Kubernetes resources cleanup completed!${NC}"
    echo ""
fi

# Phase 2: Terraform Infrastructure Destruction
echo -e "${BLUE}"
echo "🏗️  Phase 2: Destroying Terraform infrastructure..."
echo "================================================="
echo -e "${NC}"

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
    terraform init
fi

# Create destroy plan
echo -e "${YELLOW}📋 Creating destruction plan...${NC}"
terraform plan -destroy -out=destroyplan

# Show what will be destroyed
echo -e "${YELLOW}📊 Resources to be destroyed:${NC}"
terraform show destroyplan | grep -E "# .* will be destroyed" || true

# Apply destruction
echo -e "${RED}💥 Destroying infrastructure...${NC}"
terraform apply destroyplan

# Phase 3: Cleanup local files
echo -e "${BLUE}"
echo "🧹 Phase 3: Cleaning up local files..."
echo "===================================="
echo -e "${NC}"

echo -e "${YELLOW}🗑️  Removing temporary files...${NC}"
rm -f destroyplan
rm -f *.pem
rm -f terraform.tfstate.backup

# Clean up kubeconfig (optional)
echo -e "${YELLOW}❓ Remove kubectl configuration for this cluster? (y/N)${NC}"
read -r CLEANUP_KUBECONFIG
if [ "$CLEANUP_KUBECONFIG" = "y" ] || [ "$CLEANUP_KUBECONFIG" = "Y" ]; then
    # Remove cluster from kubeconfig
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "book-review-eks")
    kubectl config delete-cluster "$CLUSTER_NAME" 2>/dev/null || true
    kubectl config delete-context "$CLUSTER_NAME" 2>/dev/null || true
    echo "✅ Kubectl configuration cleaned up"
fi

echo -e "${GREEN}"
echo "🎉 Infrastructure destroyed successfully!"
echo "======================================="
echo "✅ All Kubernetes resources removed"
echo "✅ All AWS infrastructure destroyed"
echo "✅ Local files cleaned up"
echo ""
echo "💡 What was cleaned up:"
echo "   - ArgoCD applications and workloads"
echo "   - Application Load Balancers (ALBs)"
echo "   - EBS volumes and persistent storage"
echo "   - EKS cluster and worker nodes"
echo "   - VPC, subnets, and security groups"
echo "   - NAT gateways and internet gateways"
echo ""
echo "🔒 Your AWS account is now clean!"
echo -e "${NC}" 