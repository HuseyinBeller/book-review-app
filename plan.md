# Deploying Argo CD to AWS EKS

Below is a practical, step-by-step plan that builds on the existing Terraform and Kubernetes manifests in this repository to get Argo CD running in your AWS EKS cluster and ready to manage the `book-review-app`.

---

## 1. Extend Terraform to Install Argo CD

Add a new Terraform file (e.g. `terraform/argocd.tf`) and re-use the Helm provider pattern that already exists in `addons.tf`.

```hcl
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

  # Expose the API / UI via AWS NLB
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # Optional: make the LB internal, add TLS, etc.
  # set { name = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal", value = "true" }

  depends_on = [module.eks]
}
```

**Apply:**

```bash
cd terraform
terraform init
terraform apply
```

Terraform will:

* Provision the `argocd` namespace.
* Install the Argo CD Helm chart.
* Create an AWS Network Load Balancer in front of the Argo CD API/UI.

---

## 2. Retrieve the Initial Admin Password & URL

```bash
# External hostname (UI/API)
kubectl get svc -n argocd argocd-server \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Bootstrap password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

Login via UI (`https://<hostname>`) or CLI:

```bash
argocd login <hostname> --username admin --password <pwd> --insecure
```

---

## 3. On-board Your Git Repository

You already keep manifests here:

* `book-review-app/manifests/apps/*` (plain YAML)
* `book-review-app/manifests/helm/book-review` (Helm chart)

Choose one of two approaches:

### 3.1. CLI Quick Start

```bash
# (Optional) Create a project
argocd proj create book-review \
  --description "Book Review Demo" \
  --dest "https://kubernetes.default.svc,book-review" \
  --src "<YOUR_GIT_REPO_URL>"

# Create an application that tracks the Helm chart directory
argocd app create book-review-helm \
  --repo "<YOUR_GIT_REPO_URL>" \
  --path "book-review-app/manifests/helm/book-review" \
  --revision main \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace book-review \
  --project book-review \
  --sync-policy automated
```

### 3.2. GitOps "App-of-Apps"

Commit an Argo CD `Application` or `ApplicationSet` YAML (e.g. `book-review-app/manifests/apps/book-review-helm.yaml`) and let Argo CD bootstrap itself automatically.

---

## 4. Secure Access & RBAC

* Change the default admin password after first login or create dedicated users.
* Integrate with your IdP (OIDC/SAML) if required.
* Use AWS IAM Roles for Service Accounts (IRSA) for workloads needing AWS permissions.

---

## 5. Automate Promotion (Optional)

You already have `values-development.yaml` and `values-production.yaml` for different environments.  Leverage:

* Separate Argo CD Applications per environment, **or**
* Argo CD ApplicationSets that template environments automatically.

---

## 6. Clean-up

Run `terraform destroy` (or `./destroy.sh`) to tear down Argo CD along with the rest of the infrastructure.  Remember to include any new resources in `destroy.sh` if you maintain it separately.

---

## 7. Summary

1. Add `kubernetes_namespace` + `helm_release` resources for Argo CD in Terraform.
2. Apply Terraform to deploy Argo CD and expose it through an AWS Load Balancer.
3. Retrieve the initial admin password and log in.
4. Register this Git repo and let Argo CD manage your application manifests.

You are now ready to use Argo CD for continuous deployment on your EKS cluster. 🎉 