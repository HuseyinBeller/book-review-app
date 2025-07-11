# Book Review Application Helm Chart

This Helm chart deploys a full-stack book review application consisting of:
- React frontend
- Express.js backend API  
- MongoDB database

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for MongoDB persistence)

## Installing the Chart

To install the chart with the release name `book-review`:

```bash
helm install book-review ./book-review
```

To install in a specific namespace:

```bash
kubectl create namespace book-review-app
helm install book-review ./book-review --namespace book-review-app
```

## Uninstalling the Chart

To uninstall/delete the `book-review` deployment:

```bash
helm uninstall book-review
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]` |

### Frontend Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.image.registry` | Frontend image registry | `docker.io` |
| `frontend.image.repository` | Frontend image repository | `huseyinbeller/book-review-frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.image.pullPolicy` | Frontend image pull policy | `IfNotPresent` |
| `frontend.replicaCount` | Number of frontend replicas | `2` |
| `frontend.service.type` | Frontend service type | `NodePort` |
| `frontend.service.port` | Frontend service port | `80` |
| `frontend.env.apiBaseUrl` | Backend API URL for frontend | `http://localhost:3001` |

### Backend Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.enabled` | Enable backend deployment | `true` |
| `backend.image.registry` | Backend image registry | `docker.io` |
| `backend.image.repository` | Backend image repository | `huseyinbeller/book-review-backend` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.replicaCount` | Number of backend replicas | `2` |
| `backend.service.type` | Backend service type | `ClusterIP` |
| `backend.service.port` | Backend service port | `3000` |

### MongoDB Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mongodb.enabled` | Enable MongoDB deployment | `true` |
| `mongodb.image.registry` | MongoDB image registry | `docker.io` |
| `mongodb.image.repository` | MongoDB image repository | `mongo` |
| `mongodb.image.tag` | MongoDB image tag | `6.0` |
| `mongodb.auth.enabled` | Enable MongoDB authentication | `true` |
| `mongodb.auth.rootUsername` | MongoDB root username | `root` |
| `mongodb.auth.rootPassword` | MongoDB root password | `example` |
| `mongodb.persistence.enabled` | Enable MongoDB persistence | `true` |
| `mongodb.persistence.size` | MongoDB persistent volume size | `8Gi` |
| `mongodb.service.port` | MongoDB service port | `27017` |

## Examples

### Install with custom values

```bash
helm install book-review ./book-review \
  --set frontend.replicaCount=3 \
  --set backend.replicaCount=3 \
  --set mongodb.persistence.size=20Gi
```

### Install with LoadBalancer service

```bash
helm install book-review ./book-review \
  --set frontend.service.type=LoadBalancer
```

### Install without persistence

```bash
helm install book-review ./book-review \
  --set mongodb.persistence.enabled=false
```

### Upgrade deployment

```bash
helm upgrade book-review ./book-review \
  --set frontend.image.tag=v2.0.0 \
  --set backend.image.tag=v2.0.0
```

## Accessing the Application

After installation, follow the notes printed by Helm to access your application. The method depends on your service configuration:

- **NodePort**: Access via `http://<node-ip>:<node-port>`
- **LoadBalancer**: Access via `http://<load-balancer-ip>`
- **ClusterIP**: Use port-forwarding with `kubectl port-forward`

## Monitoring

Check the status of your deployment:

```bash
kubectl get pods -l app.kubernetes.io/instance=book-review
kubectl get services -l app.kubernetes.io/instance=book-review
```

View logs:

```bash
kubectl logs -l app.kubernetes.io/component=frontend
kubectl logs -l app.kubernetes.io/component=backend  
kubectl logs -l app.kubernetes.io/component=mongodb
```

## Troubleshooting

1. **Pod stuck in Pending**: Check if PVC can be bound
   ```bash
   kubectl get pvc
   kubectl describe pvc book-review-mongodb-pvc
   ```

2. **Backend can't connect to MongoDB**: Verify service names and ports
   ```bash
   kubectl get svc
   kubectl logs -l app.kubernetes.io/component=backend
   ```

3. **Frontend can't reach backend**: Check if `frontend.env.apiBaseUrl` is correctly configured for your environment 