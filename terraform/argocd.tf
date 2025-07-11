# Namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Argo CD Helm chart
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"          # Pin a stable version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Use ClusterIP since we'll access via ALB ingress
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Configure server for ingress access
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  # Set base href for subpath routing
  set {
    name  = "server.extraArgs[1]"
    value = "--basehref=/argocd"
  }

  # Configure for ingress subpath
  set {
    name  = "server.config.url"
    value = "https://your-domain.com/argocd"  # Will be updated via ingress
  }

  depends_on = [module.eks]
} 