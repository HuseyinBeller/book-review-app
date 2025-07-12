# EKS Blueprints Addons
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.21" # Ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Enable AWS Load Balancer Controller
  enable_aws_load_balancer_controller = true

  # EKS Addons
  eks_addons = {
    # Enable EBS CSI Driver for persistent volumes
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Configure AWS Load Balancer Controller
  aws_load_balancer_controller = {
    chart         = "aws-load-balancer-controller"
    chart_version = "1.8.1"
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"
    values = [
      yamlencode({
        clusterName = module.eks.cluster_name
        region      = var.aws_region
        vpcId       = module.vpc.vpc_id
        serviceAccount = {
          create = true
          name   = "aws-load-balancer-controller"
        }
      })
    ]
  }

  # Add common tags to all resources
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    module.eks,
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
} 