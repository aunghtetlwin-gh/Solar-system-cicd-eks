# Argo CD GitOps

Install Argo CD after Terraform creates EKS:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
```

Install the Solar System Argo CD resources:

```bash
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applications/
```

Apps:

- `solar-system-platform`: shared cluster resources
- `solar-system-dev`: auto-syncs `kubernetes/overlays/dev`
- `solar-system-prod`: syncs `kubernetes/overlays/prod` for promotion

Open the Argo CD UI locally:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath='{.data.password}' | base64 -d
```

Open:

```text
https://localhost:8080
```

Promotion flow:

```text
GitHub Actions updates the dev overlay image tag
Argo CD auto-syncs dev
Copy the tested dev image tag into the prod overlay
Merge the prod promotion PR
Argo CD syncs prod
```
