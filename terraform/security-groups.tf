# # Security group for EKS cluster
# resource "aws_security_group" "eks_cluster" {
#   name_prefix = "${var.cluster_name}-cluster-"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.cluster_name}-cluster-sg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# # Security group for EKS worker nodes
# resource "aws_security_group" "eks_nodes" {
#   name_prefix = "${var.cluster_name}-nodes-"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "Allow nodes to communicate with each other"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     self        = true
#   }

#   ingress {
#     description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
#     from_port   = 1025
#     to_port     = 65535
#     protocol    = "tcp"
#     security_groups = [aws_security_group.eks_cluster.id]
#   }

#   ingress {
#     description = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     security_groups = [aws_security_group.eks_cluster.id]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.cluster_name}-nodes-sg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# # Security group for Application Load Balancer
# resource "aws_security_group" "alb" {
#   name_prefix = "${var.project_name}-alb-"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.project_name}-alb-sg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# # Security group for database (MongoDB)
# resource "aws_security_group" "database" {
#   name_prefix = "${var.project_name}-db-"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "MongoDB port"
#     from_port   = 27017
#     to_port     = 27017
#     protocol    = "tcp"
#     security_groups = [aws_security_group.eks_nodes.id]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.project_name}-db-sg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# # Security group for backend service
# resource "aws_security_group" "backend" {
#   name_prefix = "${var.project_name}-backend-"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "Backend API port"
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     security_groups = [aws_security_group.eks_nodes.id, aws_security_group.alb.id]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.project_name}-backend-sg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# # Security group for frontend service
# resource "aws_security_group" "frontend" {
#   name_prefix = "${var.project_name}-frontend-"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "Frontend port"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     security_groups = [aws_security_group.alb.id]
#   }

#   ingress {
#     description = "Frontend HTTPS port"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     security_groups = [aws_security_group.alb.id]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.project_name}-frontend-sg"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# } 