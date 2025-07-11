# 🚀 Book Review App - Complete ArgoCD GitOps Deployment Guide

This guide provides the complete deployment sequence for your ArgoCD GitOps project with EKS, ALB integration, and custom domain support.

## 📋 **Project Overview**

**Architecture:**
- **EKS Cluster**: Kubernetes cluster on AWS
- **ArgoCD**: GitOps controller for continuous deployment
- **ALB**: Single Application Load Balancer for all services
- **Custom Domain**: `book-review.curtisdev.online` with SSL
- **Applications**: React frontend, Express.js backend, MongoDB

**Access URLs:**
- **📱 Frontend**: `https://book-review.curtisdev.online/`
- **🔌 Backend API**: `https://book-review.curtisdev.online/api`
- **⚙️ ArgoCD UI**: `https://book-review.curtisdev.online/argocd`

---

## 🎯 **Phase 1: Prerequisites & Setup**

### **1.1 Tools Installation**

Verify you have these tools installed:

```powershell
# Check required tools
aws --version          # AWS CLI v2+
terraform --version    # Terraform 1.0+
kubectl version --client  # kubectl latest
git --version         # Git
```

**Installation links if needed:**
- [AWS CLI v2](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/downloads)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

### **1.2 AWS Configuration**

```powershell
# Configure AWS credentials
aws configure

# Use these settings:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]  
# Default region name: eu-central-1
# Default output format: json

# Verify AWS connection
aws sts get-caller-identity
```

### **1.3 Terraform Variables Setup**

```powershell
cd terraform

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
```

**Required `terraform.tfvars` configuration:**
```hcl
# AWS Configuration
aws_region = "eu-central-1"

# EKS Cluster Configuration
cluster_name    = "book-review-eks"
cluster_version = "1.32"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Worker Nodes Configuration
node_instance_types    = ["t3.medium"]    # Recommended for production
node_desired_capacity  = 2
node_min_capacity      = 2
node_max_capacity      = 4

# Project Configuration
environment  = "production"               # or "dev"
project_name = "book-review"
```

---

## ⚙️ **Phase 2: Infrastructure Deployment**

### **2.1 Automated Deployment (Recommended)**

Your project includes a deployment script:

```powershell
cd terraform

# Run automated deployment script
.\deploy.sh

# The script will:
# ✅ Check all prerequisites
# ✅ Initialize Terraform
# ✅ Validate configuration
# ✅ Create deployment plan
# ✅ Deploy infrastructure
# ✅ Configure kubectl
```

### **2.2 Manual Deployment (Alternative)**

If you prefer manual control:

```powershell
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review deployment plan
terraform plan

# Deploy infrastructure (15-20 minutes)
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name book-review-eks
```

### **2.3 Verify Infrastructure**

```powershell
# Check EKS cluster nodes
kubectl get nodes
# Expected: 2 nodes in Ready state

# Check ArgoCD installation
kubectl get pods -n argocd
# Expected: All pods Running

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | Select-String "aws-load-balancer-controller"
# Expected: Controller pods running

# Check EKS add-ons
kubectl get pods -n kube-system
# Expected: CoreDNS, kube-proxy, VPC CNI pods running
```

**Expected Infrastructure:**
- ✅ **EKS Cluster**: `book-review-eks` in eu-central-1
- ✅ **Worker Nodes**: 2 t3.medium instances
- ✅ **ArgoCD**: Running in `argocd` namespace
- ✅ **ALB Controller**: Installed and ready
- ✅ **EKS Add-ons**: CoreDNS, kube-proxy, VPC CNI, EBS CSI

---

## 🚀 **Phase 3: ArgoCD Application Deployment**

### **3.1 Get ArgoCD Admin Password**

```powershell
# Retrieve initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | % {[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))}

# Save this password - you'll need it for ArgoCD UI access
# Example output: xY9k2mNvBqL8rZ4t
```

### **3.2 Deploy Application via ArgoCD**

```powershell
# Deploy your book review application
kubectl apply -f book-review-app/manifests/apps/book-review-helm-with-ingress.yaml

# Monitor ArgoCD application deployment
kubectl get application -n argocd book-review-helm-app-with-ingress -w

# Check application status
kubectl describe application book-review-helm-app-with-ingress -n argocd
```

### **3.3 Verify Application Deployment**

```powershell
# Check application namespace creation
kubectl get namespace book-review

# Check application pods
kubectl get pods -n book-review
# Expected: frontend (2), backend (2), mongodb (1) pods

# Check services
kubectl get svc -n book-review
# Expected: frontend, backend, mongodb services

# Check persistent volumes
kubectl get pvc -n book-review
# Expected: MongoDB PVC created and bound
```

**Expected Application Components:**
- ✅ **Frontend**: 2 React app replicas
- ✅ **Backend**: 2 Express.js API replicas  
- ✅ **MongoDB**: 1 database instance with persistence
- ✅ **Services**: ClusterIP services for internal communication
- ✅ **Ingress**: ALB ingress with SSL certificate

---

## 🌐 **Phase 4: DNS Configuration**

### **4.1 Get ALB Hostname**

```powershell
# Wait for ALB creation (2-3 minutes)
kubectl get ingress -n book-review

# Get ALB DNS name
kubectl get ingress book-review-ingress -n book-review -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Example output: k8s-bookrevi-bookrevi-1234567890-1234567890.eu-central-1.elb.amazonaws.com
```

### **4.2 Configure DNS Record**

In your domain provider (GoDaddy or other):

1. **Go to DNS Management**
2. **Create CNAME Record:**
   - **Type**: CNAME
   - **Name**: `book-review.curtisdev.online`
   - **Value**: `<ALB-HOSTNAME-FROM-ABOVE>`
   - **TTL**: 300 (5 minutes)

### **4.3 Verify DNS Propagation**

```powershell
# Check DNS resolution (may take 5-10 minutes)
nslookup book-review.curtisdev.online

# Test connectivity
curl -I https://book-review.curtisdev.online/
```

---

## 🎉 **Phase 5: Access & Verification**

### **5.1 Access Your Applications**

After DNS propagation (5-10 minutes):

**🖥️ Frontend Application:**
```
https://book-review.curtisdev.online/
```

**🔌 Backend API:**
```
https://book-review.curtisdev.online/api
```

**⚙️ ArgoCD UI:**
```
https://book-review.curtisdev.online/argocd
```

### **5.2 ArgoCD Login**

1. **Open Browser**: Navigate to `https://book-review.curtisdev.online/argocd`
2. **Login Credentials**:
   - **Username**: `admin`
   - **Password**: (retrieved in Phase 3.1)

### **5.3 End-to-End Verification**

```powershell
# Test frontend
curl -I https://book-review.curtisdev.online/

# Test backend API
curl https://book-review.curtisdev.online/api/health

# Test ArgoCD
curl -I https://book-review.curtisdev.online/argocd

# Check SSL certificate
curl -I https://book-review.curtisdev.online/ | Select-String "HTTP"
# Expected: HTTP/2 200 (indicates SSL working)
```

---

## 📊 **Deployment Timeline**

| **Phase** | **Duration** | **What's Happening** |
|-----------|--------------|---------------------|
| **Infrastructure** | 15-20 min | EKS cluster creation, node groups, add-ons |
| **ArgoCD Setup** | 2-3 min | ArgoCD pods starting, webhooks configured |
| **Application Deploy** | 3-5 min | Helm chart rendering, pods starting |
| **ALB Creation** | 2-3 min | Load balancer provisioning |
| **DNS Propagation** | 5-10 min | CNAME record spreading globally |
| **🎯 Total Time** | **25-35 min** | **Complete deployment** |

---

## 🔍 **Monitoring Commands**

### **Infrastructure Monitoring**
```powershell
# Monitor terraform deployment
terraform apply -auto-approve

# Check EKS cluster status
aws eks describe-cluster --name book-review-eks --region eu-central-1

# Monitor node group status
kubectl get nodes -o wide
```

### **Application Monitoring**
```powershell
# Monitor ArgoCD application
kubectl get application -n argocd -w

# Monitor pod startup
kubectl get pods -n book-review -w

# Check pod logs
kubectl logs -n book-review deployment/book-review-frontend
kubectl logs -n book-review deployment/book-review-backend
kubectl logs -n book-review deployment/book-review-mongodb
```

### **ALB Monitoring**
```powershell
# Monitor ingress creation
kubectl get ingress -n book-review -w

# Check ALB status
kubectl describe ingress book-review-ingress -n book-review

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### **ArgoCD Monitoring**
```powershell
# Check ArgoCD application status
kubectl describe application book-review-helm-app-with-ingress -n argocd

# Check ArgoCD sync status
kubectl get application -n argocd book-review-helm-app-with-ingress -o yaml

# ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server
```

---

## 🚨 **Troubleshooting Guide**

### **1. Infrastructure Issues**

**EKS Cluster Creation Fails:**
```powershell
# Check AWS permissions
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME

# Check region and availability zones
aws ec2 describe-availability-zones --region eu-central-1

# Check VPC limits
aws ec2 describe-vpcs --region eu-central-1
```

**Node Group Issues:**
```powershell
# Check node group status
aws eks describe-nodegroup --cluster-name book-review-eks --nodegroup-name book-review-eks-nodes --region eu-central-1

# Check worker node logs
kubectl describe nodes
```

### **2. Application Issues**

**Image Pull Errors:**
```powershell
# Verify Docker images exist
docker pull huseyinbeller/book-review-frontend:latest
docker pull huseyinbeller/book-review-backend:latest

# Check if using correct image registry
kubectl describe pod -n book-review -l app=frontend
```

**Pod CrashLoopBackOff:**
```powershell
# Check pod logs
kubectl logs -n book-review deployment/book-review-backend --previous

# Check resource limits
kubectl describe pod -n book-review -l app=backend

# Check MongoDB connection
kubectl exec -n book-review deployment/book-review-backend -- curl -I mongodb:27017
```

**MongoDB Persistence Issues:**
```powershell
# Check storage class
kubectl get storageclass

# Check PVC status
kubectl describe pvc -n book-review

# Check EBS CSI driver
kubectl get pods -n kube-system | Select-String "ebs-csi"
```

### **3. ALB Issues**

**ALB Not Creating:**
```powershell
# Check ALB controller status
kubectl get pods -n kube-system | Select-String "aws-load-balancer-controller"

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify IAM permissions
aws iam get-role --role-name book-review-eks-aws-load-balancer-controller
```

**Ingress Not Getting Address:**
```powershell
# Check ingress annotations
kubectl describe ingress book-review-ingress -n book-review

# Check target groups
aws elbv2 describe-target-groups --region eu-central-1

# Check security groups
kubectl describe ingress book-review-ingress -n book-review | Select-String "Events"
```

### **4. SSL Certificate Issues**

**Certificate Not Working:**
```powershell
# Verify certificate ARN in ingress
kubectl get ingress book-review-ingress -n book-review -o yaml | Select-String "certificate-arn"

# Check certificate status in AWS
aws acm describe-certificate --certificate-arn "arn:aws:acm:eu-central-1:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344" --region eu-central-1

# Test SSL connection
openssl s_client -connect book-review.curtisdev.online:443 -servername book-review.curtisdev.online
```

### **5. ArgoCD Issues**

**Application Not Syncing:**
```powershell
# Check ArgoCD application status
kubectl get application -n argocd book-review-helm-app-with-ingress -o yaml

# Force sync
kubectl patch application book-review-helm-app-with-ingress -n argocd --type merge -p='{"operation":{"sync":{}}}'

# Check repository access
kubectl exec -n argocd deployment/argocd-repo-server -- git ls-remote https://github.com/HuseyinBeller/book-review-app.git
```

**Helm Template Issues:**
```powershell
# Validate Helm chart locally
helm template book-review book-review-app/manifests/helm/book-review/ -f book-review-app/manifests/helm/book-review/values-with-ingress.yaml

# Check ArgoCD repo server logs
kubectl logs -n argocd deployment/argocd-repo-server
```

---

## 🔧 **Configuration Reference**

### **Key Configuration Files**

**Terraform Variables** (`terraform/terraform.tfvars`):
```hcl
aws_region = "eu-central-1"
cluster_name = "book-review-eks"
cluster_version = "1.32"
node_instance_types = ["t3.medium"]
```

**ArgoCD Application** (`book-review-app/manifests/apps/book-review-helm-with-ingress.yaml`):
```yaml
repoURL: https://github.com/HuseyinBeller/book-review-app.git
path: book-review-app/manifests/helm/book-review
valueFiles: values-with-ingress.yaml
```

**Helm Values** (`book-review-app/manifests/helm/book-review/values-with-ingress.yaml`):
```yaml
ingress:
  enabled: true
  hosts:
    - host: book-review.curtisdev.online
  certificateArn: "arn:aws:acm:eu-central-1:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344"
```

### **AWS Resources Created**

- **EKS Cluster**: `book-review-eks`
- **Node Group**: Worker nodes in private subnets
- **VPC**: `10.0.0.0/16` with public/private subnets
- **ALB**: Application Load Balancer with SSL
- **Security Groups**: EKS cluster, nodes, ALB
- **IAM Roles**: EKS service role, node group role, ALB controller role

---

## 🎯 **Final Checklist**

### **Before Deployment**
- ✅ AWS CLI configured with eu-central-1 region
- ✅ Terraform variables customized in `terraform.tfvars`
- ✅ SSL certificate ARN validated in values file
- ✅ Docker images available: `huseyinbeller/book-review-frontend:latest`, `huseyinbeller/book-review-backend:latest`
- ✅ DNS provider access for CNAME record creation
- ✅ Git repository accessible: `https://github.com/HuseyinBeller/book-review-app.git`

### **After Deployment**
- ✅ EKS cluster accessible via kubectl
- ✅ ArgoCD UI accessible with admin credentials
- ✅ All application pods running and healthy
- ✅ ALB created with healthy targets
- ✅ DNS pointing to ALB hostname
- ✅ SSL certificate working correctly
- ✅ Frontend, backend, and ArgoCD accessible via custom domain

---

## 🚀 **Next Steps**

### **Development Workflow**
1. **Make code changes** in your application
2. **Build and push** new Docker images
3. **Update image tags** in Helm values or ArgoCD parameters
4. **ArgoCD automatically syncs** changes from Git
5. **Verify deployment** in ArgoCD UI

### **Operational Tasks**
- **Monitor** applications via ArgoCD UI
- **Scale** applications by updating replica counts
- **Update** Kubernetes versions via Terraform
- **Backup** MongoDB data using EBS snapshots
- **Monitor costs** via AWS Cost Explorer

### **Security Enhancements**
- Enable **pod security standards**
- Configure **network policies**
- Set up **AWS WAF** for ALB
- Enable **VPC Flow Logs**
- Configure **AWS GuardDuty**

---

## 🎉 **Congratulations!**

You now have a **production-ready GitOps deployment** with:

✅ **Kubernetes cluster** running on AWS EKS
✅ **ArgoCD GitOps** for continuous deployment
✅ **Application Load Balancer** with SSL termination
✅ **Custom domain** with HTTPS access
✅ **Automated scaling** and high availability
✅ **Infrastructure as Code** with Terraform

Your book review application is accessible at:
**🌐 https://book-review.curtisdev.online**

**Happy deploying!** 🚀 