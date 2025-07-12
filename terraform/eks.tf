# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.3"

  cluster_name                   = var.name
  cluster_version                = var.k8s_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = false
  create_node_security_group    = false

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    eks-node = {
      instance_types = ["t2.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
  }
}

# Generate a key pair for EC2 instances (optional - for SSH access)
resource "tls_private_key" "eks_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks_key_pair" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.eks_key.public_key_openssh

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Save private key to local file
resource "local_file" "private_key" {
  content  = tls_private_key.eks_key.private_key_pem
  filename = "${path.module}/${var.name}-key.pem"
  file_permission = "0600"
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {} 