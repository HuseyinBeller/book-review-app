# AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.5.4"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }

  depends_on = [
    module.eks
  ]
}

# ====================================================================
# EBS CSI Driver - Enhanced Configuration
# ====================================================================

# IAM Policy Document for EBS CSI Driver IRSA
data "aws_iam_policy_document" "ebs_csi_irsa_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

# EBS CSI Driver IAM Role for IRSA (IAM Roles for Service Accounts)
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_irsa_policy.json

  tags = merge({
    Name        = "${var.cluster_name}-ebs-csi-driver-role"
    Environment = var.environment
    Project     = var.project_name
    Component   = "EBS-CSI-Driver"
    ManagedBy   = "Terraform"
  })
}

# Attach AWS managed policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# EBS CSI Driver EKS Managed Add-on (Recommended Approach)
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_addon_version
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = var.ebs_csi_resolve_conflicts_on_create
  resolve_conflicts_on_update = var.ebs_csi_resolve_conflicts_on_update

  tags = merge({
    Name        = "${var.cluster_name}-ebs-csi-driver"
    Environment = var.environment
    Project     = var.project_name
    Component   = "EBS-CSI-Driver"
    ManagedBy   = "EKS-Addon"
    Version     = var.ebs_csi_addon_version
  })

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver_policy
  ]
}

# CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = "v1.10.1-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = "v1.27.3-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "vpc-cni"
  addon_version     = "v1.13.4-eksbuild.1"
  resolve_conflicts = "OVERWRITE"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
} 