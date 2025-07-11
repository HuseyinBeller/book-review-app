# 🎯 Complete Deployment Guide

This guide provides the **correct deployment sequence** for your ArgoCD GitOps project based on your complete codebase analysis.

## 📋 **Prerequisites & Setup**

### 1.1 **Verify Tools Installation**
```powershell
# Check required tools
aws --version          # AWS CLI v2+
terraform --version    # Terraform 1.0+
kubectl version --client  # kubectl latest
git --version         # Git

# Configure AWS credentials
aws configure
# Region: eu-central-1 (as per your terraform.tfvars.example)
```

### 1.2 **Configure Terraform Variables**
```powershell
cd terraform

# Copy and customize your configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - aws_region = "eu-central-1"
# - cluster_name = "book-review-eks"  
# - cluster_version = "1.32"
# - Adjust node types/capacity as needed
```

## 🏗️ **Phase 2: Infrastructure Deployment**

### 2.1 **Automated Deployment (Recommended)**
```powershell
# Your project includes a deployment script
.\deploy.sh

# This script will:
# ✅ Check prerequisites
# ✅ Initialize terraform
# ✅ Validate configuration  
# ✅ Create deployment plan
# ✅ Deploy infrastructure
# ✅ Configure kubectl
```

### 2.2 **Manual Deployment (Alternative)**
```powershell
cd terraform

# Initialize and validate
terraform init
terraform validate
terraform plan

# Deploy infrastructure (15-20 minutes)
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name book-review-eks
```

### 2.3 **Verify Infrastructure**
```powershell
# Check EKS cluster
kubectl get nodes
# Should show 2 nodes in Ready state

# Check ArgoCD installation
kubectl get pods -n argocd
# All pods should be Running

# Check ALB Controller
kubectl get pods -n kube-system | Select-String "aws-load-balancer-controller"
# Should show controller pods running
```

## 🎯 **Phase 3: ArgoCD Application Deployment**

### 3.1 **Get ArgoCD Admin Password**
```powershell
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | % {[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))}

# Save this password for ArgoCD UI access
```

### 3.2 **Deploy Application via ArgoCD**
```powershell
# Deploy your book review application
kubectl apply -f book-review-app/manifests/apps/book-review-helm-with-ingress.yaml

# Monitor ArgoCD application
kubectl get application -n argocd book-review-helm-app-with-ingress -w
```

### 3.3 **Verify Application Deployment**
```powershell
# Check application pods
kubectl get pods -n book-review

# Check services
kubectl get svc -n book-review

# Check ingress
kubectl get ingress -n book-review
```

## 🌐 **Phase 4: DNS Configuration**

### 4.1 **Get ALB Hostname**
```powershell
# Get ALB DNS name
kubectl get ingress book-review-ingress -n book-review -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 4.2 **Configure DNS Record**
In your domain provider (GoDaddy), create:
- **Type**: CNAME
- **Name**: `book-review.curtisdev.online`  
- **Value**: `<ALB-HOSTNAME-FROM-ABOVE>`
- **TTL**: 300 (5 minutes)

## 🎉 **Phase 5: Access & Verification**

### 5.1 **Access Your Applications**
After DNS propagation (5-10 minutes):
- **📱 Frontend**: `https://book-review.curtisdev.online/`
- **🔌 Backend API**: `https://book-review.curtisdev.online/api`
- **⚙️ ArgoCD UI**: `https://book-review.curtisdev.online/argocd`

### 5.2 **Verify End-to-End**
```powershell
# Test frontend
curl -I https://book-review.curtisdev.online/

# Test backend API  
curl https://book-review.curtisdev.online/api/health

# Test ArgoCD
curl -I https://book-review.curtisdev.online/argocd
```

## 📊 **Deployment Architecture Overview**

```
🔧 Prerequisites → ⚙️ Infrastructure → 🚀 Application → 🌐 DNS → 🎉 Access
     ↓                    ↓                ↓            ↓         ↓
AWS CLI, Terraform   →  EKS Cluster   →  ArgoCD    →  CNAME  →  URLs
kubectl, Git        →  ArgoCD         →  Helm      →  Record →  Working
                    →  ALB Controller →  Pods      →         →
```

## 🎛️ **Key Configuration Points**

### **Your Terraform Configuration**
```hcl
# From your terraform.tfvars.example
aws_region = "eu-central-1"           # Your target region
cluster_name = "book-review-eks"      # EKS cluster name
cluster_version = "1.32"              # Latest Kubernetes version
node_instance_types = ["t2.medium"]   # Worker node size
```

### **Your ArgoCD Application**
```yaml
# From book-review-helm-with-ingress.yaml
repoURL: https://github.com/HuseyinBeller/book-review-app.git
path: book-review-app/manifests/helm/book-review
valueFiles: values-with-ingress.yaml  # Custom domain config
```

### **Your SSL Certificate** 
```yaml
# Already configured in values-with-ingress.yaml
certificateArn: "arn:aws:acm:eu-central-1:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344"
```

## ⏱️ **Expected Deployment Timeline**

| **Phase** | **Duration** | **What's Happening** |
|-----------|--------------|---------------------|
| **Infrastructure** | 15-20 min | EKS cluster creation, node groups, add-ons |
| **ArgoCD Setup** | 2-3 min | ArgoCD pods starting, webhooks configured |
| **Application Deploy** | 3-5 min | Helm chart rendering, pods starting |
| **ALB Creation** | 2-3 min | Load balancer provisioning |
| **DNS Propagation** | 5-10 min | CNAME record spreading globally |

## 🔍 **Monitoring Commands**

```powershell
# Monitor infrastructure deployment
terraform apply -auto-approve

# Monitor ArgoCD application
kubectl get application -n argocd -w

# Monitor pod startup
kubectl get pods -n book-review -w

# Monitor ingress creation  
kubectl get ingress -n book-review -w

# Check ALB status
kubectl describe ingress book-review-ingress -n book-review
```

## 🚨 **Common Issues & Solutions**

### **1. Image Pull Errors**
```powershell
# Check if your Docker images exist
docker pull huseyinbeller/book-review-frontend:latest
docker pull huseyinbeller/book-review-backend:latest
```

### **2. ALB Not Creating**
```powershell
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### **3. ArgoCD Sync Issues**
```powershell
# Check ArgoCD application status
kubectl describe application book-review-helm-app-with-ingress -n argocd
```

### **4. DNS Not Resolving**
```powershell
# Test DNS resolution
nslookup book-review.curtisdev.online

# Check CNAME record
dig book-review.curtisdev.online CNAME
```

### **5. SSL Certificate Issues**
```powershell
# Verify certificate region matches (eu-central-1)
aws acm list-certificates --region eu-central-1

# Check certificate status
aws acm describe-certificate --certificate-arn "arn:aws:acm:eu-central-1:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344" --region eu-central-1
```

## 🎯 **Final Checklist**

- ✅ AWS CLI configured with eu-central-1 region
- ✅ Terraform variables customized  
- ✅ SSL certificate ARN validated
- ✅ Docker images available on Docker Hub
- ✅ DNS provider access for CNAME record
- ✅ Git repository accessible (public repo)

## 🔧 **EKS Add-ons Explained**

### **Why These Add-ons are Essential:**

#### **1. CoreDNS** 📡
- **Service Discovery**: Frontend finds backend by name (`book-review-backend`)
- **Pod Communication**: Backend connects to MongoDB using service names
- **ArgoCD Communication**: ArgoCD components talk to each other

#### **2. kube-proxy** 🔄
- **Load Balancing**: Distributes traffic between your 2 frontend/backend replicas
- **ALB Integration**: Routes traffic from ALB to your pods correctly
- **Health Checks**: Ensures traffic only goes to healthy pods

#### **3. VPC CNI** 🌐
- **Pod Networking**: Each pod gets a real AWS VPC IP address
- **ALB Target Groups**: ALB can directly target pod IPs
- **Performance**: Direct VPC routing (no overlay network overhead)

## 🚀 **GitOps Workflow**

### **How It Works:**
1. **Code Changes**: Push to your GitHub repository
2. **ArgoCD Detection**: Monitors repository for changes
3. **Helm Rendering**: Converts Helm chart to Kubernetes manifests
4. **Application Sync**: Deploys changes to EKS cluster
5. **Health Monitoring**: Ensures application is healthy

### **ArgoCD Benefits:**
- ✅ **Declarative**: Infrastructure as Code
- ✅ **Automated**: Continuous deployment
- ✅ **Auditable**: Full deployment history
- ✅ **Rollback**: Easy revert to previous versions

## 🎉 **Success Indicators**

When deployment is successful, you should see:

### **Infrastructure**
```powershell
kubectl get nodes
# NAME                                         STATUS   ROLES    AGE   VERSION
# ip-10-0-1-xxx.eu-central-1.compute.internal Ready    <none>   10m   v1.32.x
# ip-10-0-2-xxx.eu-central-1.compute.internal Ready    <none>   10m   v1.32.x
```

### **ArgoCD**
```powershell
kubectl get pods -n argocd
# All pods STATUS: Running
```

### **Application**
```powershell
kubectl get pods -n book-review
# book-review-frontend-xxx   1/1   Running
# book-review-backend-xxx    1/1   Running  
# book-review-mongodb-xxx    1/1   Running
```

### **URLs Working**
- **Frontend**: Returns HTML page
- **Backend**: Returns JSON API responses
- **ArgoCD**: Shows login page

## 🔄 **Cleanup (When Needed)**

```powershell
# Destroy infrastructure
cd terraform
terraform destroy

# This will remove:
# - EKS cluster
# - ALB load balancer
# - All associated AWS resources
```

## 📞 **Support & Troubleshooting**

If you encounter issues:

1. **Check AWS Console**: EKS, EC2, Load Balancers
2. **Review Logs**: kubectl logs for pod issues
3. **Verify DNS**: Ensure CNAME record is correct
4. **ArgoCD UI**: Check application sync status
5. **Terraform State**: Ensure resources are properly created

## 🎊 **Congratulations!**

You now have a **production-ready GitOps setup** with:
- ✅ **EKS cluster** with managed add-ons
- ✅ **ArgoCD GitOps** workflow  
- ✅ **ALB integration** with SSL
- ✅ **Custom domain** support
- ✅ **Automated deployment** pipeline

Your book review application is accessible at `https://book-review.curtisdev.online` with full GitOps capabilities! 🚀 