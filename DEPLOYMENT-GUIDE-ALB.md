# Book Review Application with ArgoCD - ALB Deployment Guide

This guide shows how to deploy both your Book Review application and ArgoCD using a single AWS Application Load Balancer with your custom domain `book-review.curtisdev.online`.

## 🏗️ Architecture Overview

```
Internet → ALB (book-review.curtisdev.online) → {
  / → Frontend (React App)
  /api → Backend (Express.js)
  /argocd → ArgoCD UI
}
```

**Benefits of this approach:**
- ✅ Single entry point for both application and ArgoCD
- ✅ Cost-effective (one ALB instead of multiple load balancers)
- ✅ Custom domain with SSL/TLS termination
- ✅ Better security with internal ClusterIP services

## 📋 Prerequisites

1. **AWS EKS Cluster** - Deployed via your existing Terraform
2. **AWS Load Balancer Controller** - Installed via your `addons.tf`
3. **ArgoCD** - Will be installed via Terraform
4. **kubectl** configured for your cluster
5. **Domain Management** - Access to `*.curtisdev.online` DNS configuration
6. **SSL Certificate** - ACM certificate for `*.curtisdev.online` (recommended)

## 🔐 SSL Certificate Setup (Using Existing Certificate)

Since you already have an SSL certificate for `*.curtisdev.online` in AWS Certificate Manager, we'll use that existing certificate:

```bash
# Find your existing certificate ARN
aws acm list-certificates --region us-west-2 --query 'CertificateSummaryList[?DomainName==`*.curtisdev.online`]'

# Or check in AWS Console: Certificate Manager → Certificates
# Look for: *.curtisdev.online
# Copy the Certificate ARN: arn:aws:acm:us-west-2:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344
```

**Note**: Your certificate ARN is already configured in the values file: `arn:aws:acm:eu-central-1:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344`

## 🚀 Step-by-Step Deployment

### Step 1: Deploy ArgoCD via Terraform

```bash
cd terraform

# Initialize and validate
terraform init
terraform validate

# Deploy ArgoCD only (configured for curtisdev.online)
terraform apply -target=kubernetes_namespace.argocd -target=helm_release.argocd

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 2: Get ArgoCD Initial Password

```bash
# Retrieve initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Example output: xY9k2mNvBqL8rZ4t
```

### Step 3: Deploy Book Review Application with Ingress

```bash
# Deploy the application with ALB ingress enabled for curtisdev.online
kubectl apply -f book-review-app/manifests/apps/book-review-helm-with-ingress.yaml

# Monitor the deployment
kubectl get application -n argocd book-review-helm-app-with-ingress -w
```

### Step 4: Configure DNS

```bash
# Get ALB hostname
ALB_HOSTNAME=$(kubectl get ingress -n book-review book-review-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB Hostname: $ALB_HOSTNAME"

# Create DNS CNAME record for your domain
# book-review.curtisdev.online → $ALB_HOSTNAME
```

**DNS Configuration Required:**
- Create a CNAME record: `book-review.curtisdev.online` → `<ALB-HOSTNAME>`

### Step 5: Access Your Applications

Once DNS propagates (5-10 minutes), access your applications:

**Access URLs:**
- **Frontend**: `https://book-review.curtisdev.online/`
- **Backend API**: `https://book-review.curtisdev.online/api`
- **ArgoCD UI**: `https://book-review.curtisdev.online/argocd`

## 🔧 Configuration Options

### Option 1: With SSL Certificate (Already Configured)

✅ **Your SSL certificate is already configured** in `values-with-ingress.yaml`:
```yaml
certificateArn: "arn:aws:acm:eu-central-1:203918847014:certificate/1bc0f35e-7458-4e38-8f8f-79f3d811a344"
```

### Option 2: Without SSL Certificate (HTTP only)

```yaml
# Disable SSL redirect for testing
parameters:
  - name: ingress.sslRedirect
    value: "false"
```

### Option 3: Different Subdomain

```yaml
# Use a different subdomain
parameters:
  - name: ingress.hosts[0].host
    value: "app.curtisdev.online"  # or any other subdomain
```

## 🎯 Using ArgoCD

### 1. Access ArgoCD UI

1. **Open Browser**: Navigate to `https://book-review.curtisdev.online/argocd`
2. **Login**: 
   - Username: `admin`
   - Password: (retrieved in Step 2)

### 2. Monitor Application

In the ArgoCD UI, you'll see:
- **Application Name**: `book-review-helm-app-with-ingress`
- **Sync Status**: Should show "Synced" when healthy
- **Resources**: All pods, services, and ingress

### 3. Manual Sync (if needed)

```bash
# Install ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd /usr/local/bin/argocd

# Login via CLI with your domain
argocd login book-review.curtisdev.online/argocd --username admin --password <your-password> --insecure

# Sync application
argocd app sync book-review-helm-app-with-ingress
```

## 📊 Monitoring and Troubleshooting

### Check ALB and DNS Status

```bash
# Check ingress status
kubectl describe ingress -n book-review book-review-ingress

# Test DNS resolution
nslookup book-review.curtisdev.online

# Test ALB accessibility
curl -I https://book-review.curtisdev.online/
```

### Check SSL Certificate

```bash
# Verify SSL certificate
openssl s_client -connect book-review.curtisdev.online:443 -servername book-review.curtisdev.online

# Check certificate details
echo | openssl s_client -connect book-review.curtisdev.online:443 -servername book-review.curtisdev.online 2>/dev/null | openssl x509 -noout -dates
```

### Common Issues

1. **DNS not resolving**: Check CNAME record configuration
2. **SSL certificate errors**: Verify certificate is in the correct region (eu-central-1)
3. **ArgoCD subpath issues**: Verify `--basehref=/argocd` argument
4. **504 Gateway Timeout**: Check ALB target group health

## 🔄 GitOps Workflow

### Update Process with Custom Domain

1. **Code Changes**: Push to repository
2. **Image Updates**: CI/CD builds new images
3. **ArgoCD Sync**: Auto-deploys to `book-review.curtisdev.online`
4. **Verify**: Test at your custom domain

### Frontend Configuration

Your React app should use relative API calls since both frontend and backend are served from the same domain:

```javascript
// In your React app, use relative URLs
const API_BASE_URL = '/api';  // This will resolve to book-review.curtisdev.online/api
```

## 🛡️ Security Best Practices

### 1. SSL/TLS Configuration

```bash
# Ensure you have a valid certificate for *.curtisdev.online
aws acm list-certificates --region us-west-2 --query 'CertificateSummaryList[?DomainName==`*.curtisdev.online`]'
```

### 2. DNS Security

- Use DNSSEC if supported by your DNS provider
- Consider using Route 53 for better AWS integration
- Set appropriate TTL values for your DNS records

### 3. WAF Protection (Optional)

```bash
# Create WAF for your domain
aws wafv2 create-web-acl \
  --name book-review-waf \
  --scope REGIONAL \
  --default-action Allow={} \
  --region us-west-2
```

## 🧹 Cleanup

```bash
# Delete ArgoCD application
kubectl delete application -n argocd book-review-helm-app-with-ingress

# Clean up DNS records
# Remove the CNAME record for book-review.curtisdev.online

# Destroy infrastructure
cd terraform
terraform destroy
```

## 📈 Production Considerations

### Domain Management

```yaml
# For production, consider:
# 1. Using Route 53 for DNS
# 2. Implementing External DNS controller
# 3. Setting up health checks
```

### SSL Certificate Management

```yaml
# Automate certificate renewal
# Monitor certificate expiration
# Use cert-manager for automated certificate management
```

---

**🎉 Congratulations!** Your Book Review application is now accessible at `https://book-review.curtisdev.online` with ArgoCD available at `https://book-review.curtisdev.online/argocd`! 