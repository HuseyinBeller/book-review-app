# EBS Storage Configuration for MongoDB

## Overview

This project uses a custom AWS EBS GP3 storage class for MongoDB persistence, optimized for database workloads with enhanced performance and security features.

## Storage Class Specifications

- **Storage Class Name**: `book-review-ebs-gp3`
- **Provisioner**: `ebs.csi.aws.com`
- **Volume Type**: GP3 (General Purpose SSD v3)
- **File System**: ext4
- **Volume Size**: 20 GiB
- **IOPS**: 3,000 (optimized for MongoDB)
- **Throughput**: 125 MB/s
- **Encryption**: Enabled
- **Reclaim Policy**: Retain (prevents accidental data loss)

## Key Features

### Performance Optimization
- **3,000 IOPS**: Provides excellent random I/O performance for MongoDB operations
- **125 MB/s throughput**: Optimized for database read/write operations
- **GP3 volumes**: Better price-performance ratio compared to GP2

### Security
- **Encryption at rest**: All data stored on EBS volumes is encrypted
- **AWS KMS integration**: Uses AWS managed encryption keys

### Reliability
- **WaitForFirstConsumer**: Volume is created in the same AZ as the consuming pod
- **Volume expansion**: Allows storage expansion without downtime
- **Retain policy**: Prevents accidental data deletion when PVC is removed

## File Structure

```
book-review-app/manifests/helm/book-review/
├── templates/
│   ├── ebs-storageclass.yaml      # Custom EBS storage class definition
│   ├── mongodb-pvc.yaml           # PVC template using the storage class
│   └── mongodb-deployment.yaml    # MongoDB deployment with volume mount
└── values-with-ingress.yaml       # Values file with storage configuration
```

## Configuration Details

### Storage Class Template (`ebs-storageclass.yaml`)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: {{ include "book-review.fullname" . }}-ebs-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Retain
```

### MongoDB Values Configuration
```yaml
mongodb:
  persistence:
    enabled: true
    storageClass: "book-review-ebs-gp3"
    size: 20Gi
    accessModes:
      - ReadWriteOnce
```

## Prerequisites

### EKS Cluster Requirements
- **EBS CSI Driver**: Must be installed and configured (included in terraform)
- **IAM Permissions**: EBS CSI driver requires proper IAM roles (IRSA configured)
- **Node Groups**: Must have EBS-optimized instances

### Terraform Configuration
The EBS CSI driver is automatically configured in `terraform/addons.tf`:
```hcl
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
}
```

## Deployment Process

1. **Infrastructure Setup**: Terraform deploys EKS with EBS CSI driver
2. **Storage Class Creation**: Helm chart creates the custom storage class
3. **PVC Creation**: MongoDB PVC references the custom storage class
4. **Volume Provisioning**: EBS volume is created automatically when pod starts

## Monitoring and Troubleshooting

### Check Storage Class
```bash
kubectl get storageclass
kubectl describe storageclass book-review-ebs-gp3
```

### Check PVC Status
```bash
kubectl get pvc -n book-review
kubectl describe pvc book-review-mongodb-pvc -n book-review
```

### Check EBS Volumes
```bash
# List volumes
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/book-review-eks,Values=owned"

# Check volume details
kubectl get pv
kubectl describe pv <pv-name>
```

### Common Issues

1. **PVC Pending**: Check if EBS CSI driver is running
2. **Volume in Wrong AZ**: Ensure WaitForFirstConsumer is set
3. **Performance Issues**: Verify IOPS and throughput settings
4. **Permission Errors**: Check IRSA configuration for EBS CSI driver

## Performance Considerations

### MongoDB Workload Optimization
- **20 GiB size**: Adequate for development and small production workloads
- **3,000 IOPS**: Handles typical MongoDB read/write patterns
- **ext4 filesystem**: Recommended for MongoDB on Linux

### Scaling Considerations
- **Volume expansion**: Can be increased without downtime
- **Multiple volumes**: Consider sharding for larger deployments
- **Backup strategy**: Use EBS snapshots for point-in-time recovery

## Cost Optimization

- **GP3 vs GP2**: GP3 provides better price-performance
- **Right-sizing**: Start with 20 GiB and expand as needed
- **Lifecycle policies**: Consider automated snapshots and cleanup

## Security Best Practices

- **Encryption**: Always enabled for compliance
- **Access control**: Use Kubernetes RBAC for PVC access
- **Network policies**: Restrict MongoDB network access
- **Monitoring**: Track volume usage and performance metrics 