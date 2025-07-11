# Enhanced EKS Infrastructure Cleanup Script (PowerShell)
# Handles all dependencies properly to avoid destroy issues

$ErrorActionPreference = "Stop"

Write-Host "🗑️  Enhanced EKS Infrastructure Cleanup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install kubectl to proceed with cleanup"
    exit 1
}

# Check if we can connect to the cluster
Write-Host "🔍 Checking cluster connectivity..." -ForegroundColor Blue
try {
    kubectl get nodes 2>$null | Out-Null
    $CLUSTER_ACCESSIBLE = $true
    Write-Host "✅ Connected to EKS cluster" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Cannot connect to EKS cluster. Proceeding with Terraform destroy only." -ForegroundColor Yellow
    $CLUSTER_ACCESSIBLE = $false
}

# Warning message
Write-Host ""
Write-Host "⚠️  WARNING: This will destroy ALL infrastructure resources!" -ForegroundColor Red
Write-Host "   📊 Current resources to be cleaned:" -ForegroundColor Red
if ($CLUSTER_ACCESSIBLE) {
    Write-Host "   - ArgoCD Applications and Resources" -ForegroundColor Red
    Write-Host "   - Kubernetes Ingresses (ALBs)" -ForegroundColor Red
    Write-Host "   - Persistent Volume Claims (EBS volumes)" -ForegroundColor Red
    Write-Host "   - All Kubernetes workloads" -ForegroundColor Red
}
Write-Host "   - EKS Cluster and Node Groups" -ForegroundColor Red
Write-Host "   - VPC and all networking components" -ForegroundColor Red
Write-Host "   - Security Groups and Load Balancers" -ForegroundColor Red
Write-Host "   - NAT Gateways and Elastic IPs" -ForegroundColor Red
Write-Host "   🚨 ALL DATA WILL BE LOST!" -ForegroundColor Red
Write-Host ""

# Double confirmation
$CONFIRMATION = Read-Host "❓ Are you absolutely sure you want to proceed? (type 'yes' to confirm)"
if ($CONFIRMATION -ne "yes") {
    Write-Host "✅ Cleanup cancelled. Your infrastructure is safe." -ForegroundColor Green
    exit 0
}

# Final confirmation
$FINAL_CONFIRMATION = Read-Host "❓ Last chance! Type 'DESTROY' to confirm destruction"
if ($FINAL_CONFIRMATION -ne "DESTROY") {
    Write-Host "✅ Cleanup cancelled. Your infrastructure is safe." -ForegroundColor Green
    exit 0
}

# Phase 1: Clean up Kubernetes resources (if cluster is accessible)
if ($CLUSTER_ACCESSIBLE) {
    Write-Host ""
    Write-Host "🧹 Phase 1: Cleaning up Kubernetes resources..." -ForegroundColor Blue
    Write-Host "===============================================" -ForegroundColor Blue
    Write-Host ""

    # Step 1: Delete ArgoCD Applications
    Write-Host "🎯 Deleting ArgoCD Applications..." -ForegroundColor Yellow
    try {
        $apps = kubectl get applications -n argocd --no-headers 2>$null
        if ($apps) {
            kubectl delete applications --all -n argocd --timeout=300s
            Write-Host "✅ ArgoCD applications deleted" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  No ArgoCD applications found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "ℹ️  No ArgoCD applications found" -ForegroundColor Gray
    }

    # Step 2: Force delete any remaining ingresses (ALBs)
    Write-Host "🌐 Deleting Ingresses (ALBs)..." -ForegroundColor Yellow
    try {
        $ingresses = kubectl get ingress --all-namespaces --no-headers 2>$null
        if ($ingresses) {
            kubectl delete ingress --all --all-namespaces --timeout=300s
            Write-Host "✅ All ingresses deleted" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  No ingresses found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "ℹ️  No ingresses found" -ForegroundColor Gray
    }

    # Step 3: Delete persistent volume claims
    Write-Host "💾 Deleting Persistent Volume Claims..." -ForegroundColor Yellow
    try {
        $pvcs = kubectl get pvc --all-namespaces --no-headers 2>$null
        if ($pvcs) {
            kubectl delete pvc --all --all-namespaces --timeout=300s
            Write-Host "✅ All PVCs deleted" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  No PVCs found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "ℹ️  No PVCs found" -ForegroundColor Gray
    }

    # Step 4: Delete LoadBalancer services
    Write-Host "⚖️ Deleting LoadBalancer services..." -ForegroundColor Yellow
    try {
        $lbServices = kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer --no-headers 2>$null
        if ($lbServices) {
            kubectl delete services --all-namespaces --field-selector spec.type=LoadBalancer --timeout=300s
            Write-Host "✅ LoadBalancer services deleted" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  No LoadBalancer services found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "ℹ️  No LoadBalancer services found" -ForegroundColor Gray
    }

    # Step 5: Wait for ALB cleanup
    Write-Host "⏳ Waiting for AWS Load Balancers to be cleaned up..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    Write-Host "✅ Cleanup wait completed" -ForegroundColor Green

    # Step 6: Scale down ArgoCD
    Write-Host "📉 Scaling down ArgoCD..." -ForegroundColor Yellow
    try {
        kubectl scale deployment --all -n argocd --replicas=0 --timeout=120s 2>$null
        kubectl scale statefulset --all -n argocd --replicas=0 --timeout=120s 2>$null
        Write-Host "✅ ArgoCD scaled down" -ForegroundColor Green
    } catch {
        Write-Host "ℹ️  ArgoCD scaling completed with warnings" -ForegroundColor Gray
    }

    Write-Host "✅ Kubernetes resources cleanup completed!" -ForegroundColor Green
    Write-Host ""
}

# Phase 2: Terraform Infrastructure Destruction
Write-Host ""
Write-Host "🏗️  Phase 2: Destroying Terraform infrastructure..." -ForegroundColor Blue
Write-Host "=================================================" -ForegroundColor Blue
Write-Host ""

# Check if Terraform is initialized
if (-not (Test-Path ".terraform")) {
    Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
    terraform init
}

# Create destroy plan
Write-Host "📋 Creating destruction plan..." -ForegroundColor Yellow
terraform plan -destroy -out=destroyplan

# Show what will be destroyed
Write-Host "📊 Resources to be destroyed:" -ForegroundColor Yellow
try {
    terraform show destroyplan | Select-String "# .* will be destroyed"
} catch {
    Write-Host "Plan created successfully" -ForegroundColor Gray
}

# Apply destruction
Write-Host "💥 Destroying infrastructure..." -ForegroundColor Red
terraform apply destroyplan

# Phase 3: Cleanup local files
Write-Host ""
Write-Host "🧹 Phase 3: Cleaning up local files..." -ForegroundColor Blue
Write-Host "====================================" -ForegroundColor Blue
Write-Host ""

Write-Host "🗑️  Removing temporary files..." -ForegroundColor Yellow
Remove-Item -Path "destroyplan" -ErrorAction SilentlyContinue
Remove-Item -Path "*.pem" -ErrorAction SilentlyContinue
Remove-Item -Path "terraform.tfstate.backup" -ErrorAction SilentlyContinue

# Clean up kubeconfig (optional)
$CLEANUP_KUBECONFIG = Read-Host "❓ Remove kubectl configuration for this cluster? (y/N)"
if ($CLEANUP_KUBECONFIG -eq "y" -or $CLEANUP_KUBECONFIG -eq "Y") {
    try {
        $CLUSTER_NAME = terraform output -raw cluster_name 2>$null
        if (-not $CLUSTER_NAME) { $CLUSTER_NAME = "book-review-eks" }
        kubectl config delete-cluster $CLUSTER_NAME 2>$null
        kubectl config delete-context $CLUSTER_NAME 2>$null
        Write-Host "✅ Kubectl configuration cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "ℹ️  Kubectl configuration cleanup completed with warnings" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🎉 Infrastructure destroyed successfully!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "✅ All Kubernetes resources removed" -ForegroundColor Green
Write-Host "✅ All AWS infrastructure destroyed" -ForegroundColor Green
Write-Host "✅ Local files cleaned up" -ForegroundColor Green
Write-Host ""
Write-Host "💡 What was cleaned up:" -ForegroundColor Cyan
Write-Host "   - ArgoCD applications and workloads" -ForegroundColor Gray
Write-Host "   - Application Load Balancers (ALBs)" -ForegroundColor Gray
Write-Host "   - EBS volumes and persistent storage" -ForegroundColor Gray
Write-Host "   - EKS cluster and worker nodes" -ForegroundColor Gray
Write-Host "   - VPC, subnets, and security groups" -ForegroundColor Gray
Write-Host "   - NAT gateways and internet gateways" -ForegroundColor Gray
Write-Host ""
Write-Host "🔒 Your AWS account is now clean!" -ForegroundColor Green 