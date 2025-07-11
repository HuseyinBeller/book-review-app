# Lifecycle Management and Dependency Prevention
# This file helps prevent common Terraform destroy issues

# Prevent accidental deletion of critical resources
locals {
  # Define resources that should be protected from accidental deletion
  protect_resources = var.environment == "production" ? true : false
}

# Data source to detect if there are any ArgoCD applications
data "external" "argocd_check" {
  count = local.protect_resources ? 1 : 0
  
  program = ["bash", "-c", <<-EOT
    if command -v kubectl &> /dev/null && kubectl get applications -n argocd 2>/dev/null | grep -q .; then
      echo '{"has_applications": "true"}'
    else
      echo '{"has_applications": "false"}'
    fi
  EOT
  ]
}

# Create a null resource to enforce cleanup order
resource "null_resource" "pre_destroy_check" {
  count = local.protect_resources ? 1 : 0
  
  # This will run before destroy to warn about remaining resources
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🔍 Checking for remaining Kubernetes resources..."
      if command -v kubectl &> /dev/null; then
        echo "ArgoCD Applications:"
        kubectl get applications -n argocd 2>/dev/null || echo "None found"
        echo "Ingresses (ALBs):"
        kubectl get ingress --all-namespaces 2>/dev/null || echo "None found"
        echo "PVCs (EBS Volumes):"
        kubectl get pvc --all-namespaces 2>/dev/null || echo "None found"
        echo "LoadBalancer Services:"
        kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer 2>/dev/null || echo "None found"
      fi
    EOT
  }
  
  # Ensure this runs before EKS destruction
  depends_on = [module.eks]
}

# Output warnings about manual cleanup steps
output "manual_cleanup_required" {
  description = "Manual cleanup steps required before terraform destroy"
  value = <<-EOT
    
    🚨 IMPORTANT: Before running 'terraform destroy', ensure you:
    
    1. Delete ArgoCD Applications:
       kubectl delete applications --all -n argocd
    
    2. Delete Ingresses (ALBs):
       kubectl delete ingress --all --all-namespaces
    
    3. Delete PVCs (EBS volumes):
       kubectl delete pvc --all --all-namespaces
    
    4. Delete LoadBalancer services:
       kubectl delete services --all-namespaces --field-selector spec.type=LoadBalancer
    
    5. Wait 2-3 minutes for AWS resources to be cleaned up
    
    Or use the enhanced destroy script:
    ./destroy-enhanced.ps1 (Windows) or ./destroy-enhanced.sh (Linux/Mac)
    
  EOT
} 