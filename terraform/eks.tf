module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = var.node_instance_types
  }

  eks_managed_node_groups = {
    blue = {
      min_size     = var.node_min_capacity
      max_size     = var.node_max_capacity
      desired_size = var.node_desired_capacity

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      disk_size = 20
      ami_type  = "AL2_x86_64"

      # Remote access configuration
      remote_access = {
        ec2_ssh_key               = aws_key_pair.eks_key_pair.key_name
        source_security_group_ids = [aws_security_group.eks_nodes.id]
      }
    }
  }



  tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

# Generate a key pair for EC2 instances
resource "tls_private_key" "eks_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks_key_pair" {
  key_name   = "${var.cluster_name}-key"
  public_key = tls_private_key.eks_key.public_key_openssh

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Save private key to local file
resource "local_file" "private_key" {
  content  = tls_private_key.eks_key.private_key_pem
  filename = "${path.module}/${var.cluster_name}-key.pem"
  file_permission = "0600"
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {} 