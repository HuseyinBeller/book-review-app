# Book Review Application - AWS EKS Infrastructure

This Terraform configuration sets up a complete AWS EKS infrastructure for deploying the Book Review application.

## Infrastructure Components

### Networking
- **VPC**: Custom VPC with configurable CIDR block
- **Public Subnets**: For load balancers and NAT gateways (3 AZs)
- **Private Subnets**: For EKS worker nodes and application pods (3 AZs)
- **NAT Gateways**: One per AZ for private subnet internet access
- **Internet Gateway**: For public subnet internet access

### EKS Cluster
- **EKS Control Plane**: Managed Kubernetes control plane
- **Worker Nodes**: EKS managed node groups with auto-scaling
- **Add-ons**: CoreDNS, kube-proxy, VPC CNI, Enhanced EBS CSI driver
- **AWS Load Balancer Controller**: For ingress and load balancing
- **IRSA Support**: IAM Roles for Service Accounts with OIDC

### Security Groups
- **EKS Cluster SG**: Control plane security group
- **EKS Nodes SG**: Worker nodes security group  
- **ALB SG**: Application Load Balancer security group
- **Database SG**: MongoDB/Database security group
- **Backend SG**: Backend API security group
- **Frontend SG**: Frontend application security group

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **kubectl** for Kubernetes management
4. Appropriate AWS IAM permissions for EKS, VPC, and EC2

## Quick Start

1. **Clone and navigate to terraform directory**:
   ```bash
   cd terraform
   ```

2. **Copy and customize variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferred settings
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region <your-region> --name <cluster-name>
   ```

## Configuration

### Essential Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-west-2` |
| `cluster_name` | EKS cluster name | `book-review-eks` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `node_instance_types` | EC2 instance types for nodes | `["t2.medium"]` |
| `node_desired_capacity` | Desired number of worker nodes | `2` |
| `node_min_capacity` | Minimum number of worker nodes | `2` |

### Customization

Edit `terraform.tfvars` to customize:
- AWS region and availability zones
- VPC and subnet CIDR blocks
- EKS cluster name and version
- Worker node instance types and scaling
- Environment and project naming

## Outputs

After successful deployment, Terraform outputs important information:
- EKS cluster endpoint and certificate authority
- VPC and subnet IDs
- Security group IDs
- Load balancer controller IAM role ARN

## Post-Deployment Steps

1. **Verify cluster access**:
   ```bash
   kubectl get nodes
   ```

2. **Create application namespace**:
   ```bash
   kubectl create namespace book-review
   ```

3. **Deploy your application**:
   ```bash
   kubectl apply -f ../book-review-app/k8s/ -n book-review
   ```

4. **Deploy ALB ingress** (to expose your frontend):
   ```bash
   kubectl apply -f examples/book-review-ingress.yaml
   ```

5. **Get the Application Load Balancer URL**:
   ```bash
   kubectl get ingress book-review-ingress -n book-review
   ```

6. **Check load balancer controller**:
   ```bash
   kubectl get pods -n kube-system | grep aws-load-balancer-controller
   ```

## Security Considerations

- EKS worker nodes are deployed in private subnets
- Security groups follow principle of least privilege
- NAT gateways enable secure internet access for private resources
- SSH key pair generated for node access (private key saved locally)

## Cost Optimization

- Uses spot instances option (commented out by default)
- Single NAT gateway option available (set `single_nat_gateway = true`)
- Configurable node scaling for cost management

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

**Warning**: This will delete all resources. Make sure to backup any important data.

## Troubleshooting

### Common Issues

1. **Insufficient IAM permissions**: Ensure your AWS credentials have necessary permissions
2. **Region availability**: Some instance types may not be available in all regions
3. **Quota limits**: Check AWS service quotas for VPC, EKS, and EC2

### Useful Commands

```bash
# Check cluster status
aws eks describe-cluster --name <cluster-name>

# Get worker nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# View load balancer controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Support

For issues related to:
- AWS EKS: Check AWS EKS documentation
- Terraform: Check Terraform AWS provider documentation
- Kubernetes: Check Kubernetes documentation 